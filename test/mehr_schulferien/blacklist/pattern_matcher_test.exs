defmodule MehrSchulferien.Blacklist.PatternMatcherTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Blacklist.PatternMatcher

  describe "to_regex_pattern/1" do
    test "converts simple pattern to regex" do
      assert PatternMatcher.to_regex_pattern("hello") == "^hello$"
    end

    test "converts * wildcard to .*" do
      # Spaces are also escaped by Regex.escape
      assert PatternMatcher.to_regex_pattern("+49 30 1234*") == "^\\+49\\ 30\\ 1234.*$"
    end

    test "converts ? wildcard to ." do
      assert PatternMatcher.to_regex_pattern("123?5") == "^123.5$"
    end

    test "escapes special regex characters" do
      assert PatternMatcher.to_regex_pattern("test.example") == "^test\\.example$"
      assert PatternMatcher.to_regex_pattern("test+example") == "^test\\+example$"
    end

    test "handles email patterns" do
      assert PatternMatcher.to_regex_pattern("info@*.schule.de") == "^info@.*\\.schule\\.de$"
    end

    test "handles combined wildcards" do
      assert PatternMatcher.to_regex_pattern("test*?value") == "^test.*.value$"
    end
  end

  describe "matches?/2" do
    test "matches simple patterns" do
      regex = PatternMatcher.to_regex_pattern("hello")
      assert PatternMatcher.matches?("hello", regex)
      refute PatternMatcher.matches?("Hello World", regex)
    end

    test "matches case-insensitively" do
      regex = PatternMatcher.to_regex_pattern("hello")
      assert PatternMatcher.matches?("HELLO", regex)
      assert PatternMatcher.matches?("Hello", regex)
      assert PatternMatcher.matches?("hElLo", regex)
    end

    test "matches * wildcard patterns" do
      regex = PatternMatcher.to_regex_pattern("+49 30 1234*")
      assert PatternMatcher.matches?("+49 30 1234567", regex)
      assert PatternMatcher.matches?("+49 30 12345678", regex)
      assert PatternMatcher.matches?("+49 30 1234", regex)
      refute PatternMatcher.matches?("+49 30 1233567", regex)
    end

    test "matches ? wildcard patterns" do
      regex = PatternMatcher.to_regex_pattern("123?5")
      assert PatternMatcher.matches?("12345", regex)
      assert PatternMatcher.matches?("12305", regex)
      refute PatternMatcher.matches?("1235", regex)
      refute PatternMatcher.matches?("123445", regex)
    end

    test "matches email patterns" do
      regex = PatternMatcher.to_regex_pattern("info@*.schule.de")
      assert PatternMatcher.matches?("info@meine.schule.de", regex)
      assert PatternMatcher.matches?("info@gymnasium.schule.de", regex)
      refute PatternMatcher.matches?("kontakt@meine.schule.de", regex)
      refute PatternMatcher.matches?("info@schule.org", regex)
    end

    test "returns false for nil" do
      regex = PatternMatcher.to_regex_pattern("test")
      refute PatternMatcher.matches?(nil, regex)
    end

    test "returns false for empty string" do
      regex = PatternMatcher.to_regex_pattern("test")
      refute PatternMatcher.matches?("", regex)
    end
  end

  describe "validate_pattern/1" do
    test "accepts valid patterns" do
      assert PatternMatcher.validate_pattern("+49 30 1234*") == :ok
      assert PatternMatcher.validate_pattern("info@*.schule.de") == :ok
      assert PatternMatcher.validate_pattern("test123") == :ok
    end

    test "rejects empty patterns" do
      assert {:error, _} = PatternMatcher.validate_pattern("")
      assert {:error, _} = PatternMatcher.validate_pattern("   ")
    end

    test "rejects overly broad patterns" do
      assert {:error, _} = PatternMatcher.validate_pattern("*")
      assert {:error, _} = PatternMatcher.validate_pattern("?")
      assert {:error, _} = PatternMatcher.validate_pattern("**")
      assert {:error, _} = PatternMatcher.validate_pattern("*@*")
    end

    test "rejects patterns that are too short (less than 4 characters)" do
      # Less than 4 characters should be rejected
      assert {:error, _} = PatternMatcher.validate_pattern("ab")
      assert {:error, _} = PatternMatcher.validate_pattern("abc")
      # 4 characters should be accepted
      assert :ok = PatternMatcher.validate_pattern("abcd")
    end

    test "rejects patterns with mostly wildcards" do
      assert {:error, _} = PatternMatcher.validate_pattern("*?*")
    end
  end

  describe "compile_pattern/1" do
    test "compiles valid patterns" do
      assert {:ok, regex} = PatternMatcher.compile_pattern("+49 30 1234*")
      assert is_struct(regex, Regex)
    end

    test "compiled pattern works for matching" do
      {:ok, regex} = PatternMatcher.compile_pattern("+49 30 1234*")
      assert Regex.match?(regex, "+49 30 12345678")
      refute Regex.match?(regex, "+49 30 1233567")
    end
  end
end
