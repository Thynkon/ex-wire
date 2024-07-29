const std = @import("std");
const testing = std.testing;
const String = @import("string").String;

const erl = @cImport({
    @cInclude("erl_nif.h");
});

export fn add(
    env: ?*erl.ErlNifEnv,
    argc: c_int,
    argv: [*c]const erl.ERL_NIF_TERM,
) erl.ERL_NIF_TERM {
    var a: c_int = 0;
    var b: c_int = 0;

    if ((argc != 2)) {
        return erl.enif_make_badarg(env);
    }

    // _ = erl.enif_get_int(env, argv[0], &a);
    _ = erl.enif_get_int(env, argv[0], &a);
    _ = erl.enif_get_int(env, argv[1], &b);

    const result = a + b;
    return erl.enif_make_int(env, result);
}

const func_count = 1;

var funcs = [func_count]erl.ErlNifFunc{
    erl.ErlNifFunc{
        .name = "add",
        .arity = 2,
        .fptr = add,
        .flags = 0,
    },
};

var entry = erl.ErlNifEntry{
    .major = erl.ERL_NIF_MAJOR_VERSION,
    .minor = erl.ERL_NIF_MINOR_VERSION,
    // .name = "Elixir.ExWire",
    .name = "Elixir.ExWire",
    .num_of_funcs = func_count,
    .funcs = &funcs,
    .load = null,
    .reload = null,
    .upgrade = null,
    .unload = null,
    .vm_variant = "beam.vanilla",
    .options = 1,
    .sizeof_ErlNifResourceTypeInit = @sizeOf(erl.ErlNifResourceTypeInit),
    .min_erts = "erts-10.4",
};

export fn nif_init() *erl.ErlNifEntry {
    return &entry;
}
