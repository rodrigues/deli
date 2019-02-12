defmodule Deli.Config.EnsureTest do
  use DeliCase
  alias Deli.Config.Ensure

  describe "ensure_boolean/0" do
    property "boolean when receives boolean" do
      check all a <- boolean() do
        assert Ensure.ensure_boolean(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&is_boolean/1) do
        assert_raise RuntimeError, fn -> Ensure.ensure_boolean(a) end
      end
    end
  end

  describe "ensure_atom/0" do
    property "atom when receives atom" do
      check all a <- atom() do
        assert Ensure.ensure_atom(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&is_atom/1) do
        assert_raise RuntimeError, fn -> Ensure.ensure_atom(a) end
      end
    end
  end

  describe "ensure_port_number/0" do
    property "port number when receives port number" do
      check all a <- 0..65_535 |> integer() do
        assert Ensure.ensure_port_number(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&(&1 in 0..65_535)) do
        assert_raise RuntimeError, fn -> Ensure.ensure_port_number(a) end
      end
    end
  end

  describe "ensure_pos_integer/0" do
    property "number when receives positive integer" do
      check all a <- positive_integer() do
        assert Ensure.ensure_pos_integer(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&(is_integer(&1) and &1 > 0)) do
        assert_raise RuntimeError, fn -> Ensure.ensure_pos_integer(a) end
      end
    end
  end

  describe "ensure_binary/0" do
    property "binary when receives binary" do
      check all a <- binary() do
        assert Ensure.ensure_binary(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&is_binary/1) do
        assert_raise RuntimeError, fn -> Ensure.ensure_binary(a) end
      end
    end
  end

  describe "ensure_atom_or_binary/0" do
    property "atom when receives atom" do
      check all a <- atom() do
        assert Ensure.ensure_atom_or_binary(a) == a
      end
    end

    property "binary when receives binary" do
      check all a <- binary() do
        assert Ensure.ensure_atom_or_binary(a) == a
      end
    end

    property "fails otherwise" do
      check all a <- term_except(&(is_atom(&1) or is_binary(&1))) do
        assert_raise RuntimeError, fn -> Ensure.ensure_atom_or_binary(a) end
      end
    end
  end
end
