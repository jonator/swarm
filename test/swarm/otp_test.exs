defmodule SwarmWeb.Auth.OTPTest do
  use ExUnit.Case, async: false
  alias SwarmWeb.Auth.OTP

  describe "generate_and_store/1" do
    test "generates a 6-digit OTP code for an email" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      # Verify code is a string with 6 digits
      assert is_binary(code)
      assert String.length(code) == 6
      assert String.match?(code, ~r/^\d{6}$/)
    end

    test "stores the OTP code in ETS" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      # Verify the code is stored in ETS
      [{^email, stored_code, _expiry}] = :ets.lookup(:otp_codes, email)
      assert stored_code == code
    end

    test "deletes old code for the same email when generating a new one" do
      email = "test@example.com"
      old_code = OTP.generate_and_store(email)
      # Ensure the old code is stored
      [{^email, ^old_code, _}] = :ets.lookup(:otp_codes, email)

      new_code = OTP.generate_and_store(email)
      # Ensure the new code is stored and old code is gone
      [{^email, stored_code, _}] = :ets.lookup(:otp_codes, email)
      assert stored_code == new_code
      refute stored_code == old_code
    end
  end

  describe "validate/2" do
    test "returns :ok for valid code" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      assert :ok == OTP.validate(email, code)
    end

    test "returns error for invalid code" do
      email = "test@example.com"
      OTP.generate_and_store(email)

      assert {:error, :invalid_code} == OTP.validate(email, "000000")
    end

    test "returns error for non-existent email" do
      assert {:error, :not_found} == OTP.validate("nonexistent@example.com", "123456")
    end

    test "returns error for expired code" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      # Manually expire the code by updating the expiry time
      expiry = System.system_time(:second) - 1
      :ets.insert(:otp_codes, {email, code, expiry})

      assert {:error, :expired} == OTP.validate(email, code)
    end

    test "deletes the OTP code after successful validation" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      assert :ok == OTP.validate(email, code)
      assert [] == :ets.lookup(:otp_codes, email)
    end

    test "deletes the OTP code after expiry check" do
      email = "test@example.com"
      code = OTP.generate_and_store(email)

      # Manually expire the code
      expiry = System.system_time(:second) - 1
      :ets.insert(:otp_codes, {email, code, expiry})

      assert {:error, :expired} == OTP.validate(email, code)
      assert [] == :ets.lookup(:otp_codes, email)
    end
  end

  describe "cleanup_expired/0" do
    test "removes expired OTP codes" do
      # Insert some expired codes
      email1 = "expired1@example.com"
      email2 = "expired2@example.com"
      email3 = "valid@example.com"

      code1 = "123456"
      code2 = "234567"
      code3 = "345678"

      now = System.system_time(:second)
      expired_time = now - 10
      valid_time = now + 300

      :ets.insert(:otp_codes, {email1, code1, expired_time})
      :ets.insert(:otp_codes, {email2, code2, expired_time})
      :ets.insert(:otp_codes, {email3, code3, valid_time})

      # Run cleanup
      OTP.cleanup_expired()

      # Check results
      assert [] == :ets.lookup(:otp_codes, email1)
      assert [] == :ets.lookup(:otp_codes, email2)
      assert [{email3, code3, valid_time}] == :ets.lookup(:otp_codes, email3)
    end
  end
end
