// The code contained here is mostly taken from https://github.com/E-xyza/zigler. Since we're using a
// subset of all its features, we removed the dependency to be independent from API changes (and
// possibly to experiment ourselves with alternative APIs)

const std = @import("std");
const e = @import("erl_nif.zig");

pub const allocator = @import("beam/allocator.zig");
pub const resource = @import("beam/resource.zig");
pub const scheduler = @import("beam/scheduler.zig");

pub const Binary = @import("beam/Binary.zig");
pub const Env = ?*e.ErlNifEnv;
pub const Pid = e.ErlNifPid;
pub const ResourceType = ?*e.ErlNifResourceType;
pub const Term = e.ERL_NIF_TERM;

/// The raw BEAM allocator with the standard Zig Allocator interface.
pub const raw_allocator = allocator.raw_allocator;

/// An allocator backed by the BEAM allocator that is able to perform allocations with a
/// greater alignment than the machine word. Doesn't release memory when resizing.
pub const large_allocator = allocator.large_allocator;

/// A General Purpose Allocator backed by beam.large_allocator.
pub const general_purpose_allocator = allocator.general_purpose_allocator;

/// Raises a generic exception
pub fn raise(env: Env, reason: []const u8) Term {
    return e.enif_raise_exception(env, make_atom(env, reason));
}

/// Raises a `:function_clause` exception
pub fn raise_function_clause_error(env: Env) Term {
    return raise(env, "function_clause");
}

/// Creates a ref
pub fn make_ref(env: Env) Term {
    return e.enif_make_ref(env);
}

/// Creates an atom from a Zig char slice
pub fn make_atom(env: Env, atom_str: []const u8) Term {
    return e.enif_make_atom_len(env, atom_str.ptr, atom_str.len);
}

/// Creates a beam `nil` atom
pub fn make_nil(env: Env) Term {
    return e.enif_make_atom(env, "nil");
}

/// Creates a beam `:ok` atom
pub fn make_ok(env: Env) Term {
    return e.enif_make_atom(env, "ok");
}

/// Helper to create an `{:ok, term}` tuple
pub fn make_ok_term(env: Env, val: Term) Term {
    return e.enif_make_tuple(env, 2, make_ok(env), val);
}

/// Helper to create an `{:ok, atom}` tuple, taking the atom value from a slice
pub fn make_ok_atom(env: Env, atom_str: []const u8) Term {
    return make_ok_term(env, make_atom(env, atom_str));
}

/// Creates a beam `:error` atom.
pub fn make_error(env: Env) Term {
    return e.enif_make_atom(env, "error");
}

/// Helper to create an `{:error, term}` tuple
pub fn make_error_term(env: Env, val: Term) Term {
    return e.enif_make_tuple(env, 2, make_error(env), val);
}

/// Helper to create an `{:error, atom}` tuple, taking the atom value from a slice
pub fn make_error_atom(env: Env, atom_str: []const u8) Term {
    return make_error_term(env, make_atom(env, atom_str));
}

/// Creates a binary term from a Zig slice
pub fn make_slice(env: Env, val: []const u8) Term {
    var result: Term = undefined;
    var bin: [*]u8 = @ptrCast([*]u8, e.enif_make_new_binary(env, val.len, &result));
    std.mem.copy(u8, bin[0..val.len], val);

    return result;
}

/// Creates a u8 value term.
pub fn make_u8(env: Env, val: u8) Term {
    return e.enif_make_uint(env, val);
}

/// Creates a u32 value term.
pub fn make_u32(env: Env, val: u32) Term {
    return e.enif_make_uint(env, val);
}

/// Creates an BEAM tuple from a Zig tuple of terms
pub fn make_tuple(env: Env, tuple: anytype) Term {
    const type_info = @typeInfo(@TypeOf(tuple));
    if (type_info != .Struct or !type_info.Struct.is_tuple)
        @compileError("invalid argument to make_tuple: not a tuple");

    var tuple_list: [tuple.len]Term = undefined;
    inline for (tuple_list) |*tuple_item, index| {
        const tuple_term = tuple[index];
        tuple_item.* = tuple_term;
    }
    return e.enif_make_tuple_from_array(env, &tuple_list, tuple.len);
}

pub const GetError = error{ArgumentError};

/// Extract a binary from a term, returning it as a slice
pub fn get_char_slice(env: Env, src_term: Term) GetError![]u8 {
    var bin: e.ErlNifBinary = undefined;
    if (e.enif_inspect_binary(env, src_term, &bin) == 0) {
        return GetError.ArgumentError;
    }

    return bin.data[0..bin.size];
}

/// Extract a u128 from a binary (little endian) term
pub fn get_u128(env: Env, src_term: Term) GetError!u128 {
    const bin = try get_char_slice(env, src_term);
    const required_length = @sizeOf(u128) / @sizeOf(u8);

    // We represent the u128 as a 16 byte binary, little endian (required by TigerBeetle)
    if (bin.len != required_length) return GetError.ArgumentError;

    return std.mem.readIntLittle(u128, bin[0..required_length]);
}

/// Extract a u64 from a term
pub fn get_u64(env: Env, src_term: Term) GetError!u64 {
    var result: c_ulong = undefined;
    if (e.enif_get_ulong(env, src_term, &result) == 0) {
        return GetError.ArgumentError;
    }

    return @intCast(u64, result);
}

/// Extract a u32 from a term
pub fn get_u32(env: Env, src_term: Term) GetError!u32 {
    var result: c_uint = undefined;
    if (e.enif_get_uint(env, src_term, &result) == 0) {
        return GetError.ArgumentError;
    }

    return @intCast(u32, result);
}

/// Extract a u16 from a term, checking it does not go outside the boundaries
pub fn get_u16(env: Env, src_term: Term) GetError!u16 {
    var result: c_uint = undefined;
    if (e.enif_get_uint(env, src_term, &result) == 0) {
        return GetError.ArgumentError;
    }

    if (result > std.math.maxInt(u16)) {
        return GetError.ArgumentError;
    }

    return @intCast(u16, result);
}

pub const TermToBinaryError = error{OutOfMemory};

/// Serializes a term to a beam.Binary
pub fn term_to_binary(env: Env, src_term: Term) TermToBinaryError!Binary {
    var bin: e.ErlNifBinary = undefined;
    if (e.enif_term_to_binary(env, src_term, &bin) == 0) {
        return error.OutOfMemory;
    }

    return Binary{ .binary = bin };
}

/// Allocates a process independent environment
pub fn alloc_env() Env {
    return e.enif_alloc_env();
}

/// Clears a process independent environment
pub fn clear_env(env: Env) void {
    e.enif_clear_env(env);
}
