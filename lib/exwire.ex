defmodule ExWire do
  @moduledoc """
  Documentation for `Exwire`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Exwire.hello()
      :world

  """

  @on_load :load_nifs

  def load_nifs do
    # :erlang.load_nif(~c"./zig_src/zig-out/lib/libexwire_nif", 0)
    :erlang.load_nif(~c"./zig_src/zig-out/lib/libexwire_nif", 0)
  end

  def add(_a, _b) do
    raise "NIF foo_test/1 not implemented"
  end
end
