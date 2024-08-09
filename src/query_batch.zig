const std = @import("std");
const assert = std.debug.assert;

const batch = @import("batch.zig");
const beam = @import("beam.zig");
const scheduler = beam.scheduler;

const tb = @import("tigerbeetle/src/tigerbeetle.zig");
const QueryFilter = tb.QueryFilter;
const QueryFilterFlags = tb.QueryFilterFlags;
pub const QueryFilterBatch = batch.Batch(QueryFilter);
pub const QueryFilterBatchResource = batch.BatchResource(QueryFilter);

pub fn create(env: beam.Env, capacity: u32) beam.Term {
    return batch.create(QueryFilter, env, capacity) catch |err| switch (err) {
        error.OutOfMemory => return beam.make_error_atom(env, "out_of_memory"),
    };
}

pub fn append(
    env: beam.Env,
    transfer_batch_resource: QueryFilterBatchResource,
    transfer_bytes: []const u8,
) !beam.Term {
    if (transfer_bytes.len != @sizeOf(QueryFilter)) return beam.raise_badarg(env);

    return batch.append(
        QueryFilter,
        env,
        transfer_batch_resource,
        transfer_bytes,
    ) catch |err| switch (err) {
        error.BatchFull => beam.make_error_atom(env, "batch_full"),
        error.LockFailed => return error.Yield,
    };
}

pub fn fetch(
    env: beam.Env,
    transfer_batch_resource: QueryFilterBatchResource,
    idx: u32,
) !beam.Term {
    return batch.fetch(
        QueryFilter,
        env,
        transfer_batch_resource,
        idx,
    ) catch |err| switch (err) {
        error.OutOfBounds => beam.make_error_atom(env, "out_of_bounds"),
        error.LockFailed => return error.Yield,
    };
}

pub fn replace(
    env: beam.Env,
    transfer_batch_resource: QueryFilterBatchResource,
    idx: u32,
    transfer_bytes: []const u8,
) !beam.Term {
    return batch.replace(
        QueryFilter,
        env,
        transfer_batch_resource,
        idx,
        transfer_bytes,
    ) catch |err| switch (err) {
        error.OutOfBounds => beam.make_error_atom(env, "out_of_bounds"),
        error.LockFailed => return error.Yield,
    };
}
