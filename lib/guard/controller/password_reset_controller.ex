defmodule Guard.Controller.PasswordReset do
  @moduledoc false
  use Guard.Controller
  alias Guard.{Authenticator, User, Users}

  plug(Guardian.Plug.EnsureAuthenticated)

  defp do_update_password(conn, user, new_password, new_password_confirmation) do
    update =
      if new_password_confirmation do
        Users.update_user(user, %{
          "password" => new_password,
          "password_confirmation" => new_password_confirmation
        })
      else
        Users.update_user(user, %{"password" => new_password})
      end

    case update do
      {:ok, _user} -> json(conn, %{ok: true})
      {:error, error} -> send_error(conn, error)
    end
  end

  def update_password(conn, %{
        "password" => password,
        "new_password" => new_password,
        "new_password_confirmation" => new_password_confirmation
      }) do
    user = Authenticator.current_user(conn)

    case User.check_password(user, password) do
      true ->
        do_update_password(conn, user, new_password, new_password_confirmation)

      false ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_error(:wrong_password)
    end
  end

  def update_password(conn, %{"password" => _password, "new_password" => _new_password} = params) do
    update_password(conn, Map.put(params, "new_password_confirmation", nil))
  end

  def update_password(conn, %{
        "new_password" => new_password,
        "new_password_confirmation" => new_password_confirmation
      }) do
    case Authenticator.current_claim_type(conn) do
      "password_reset" ->
        user = Authenticator.current_user(conn)
        do_update_password(conn, user, new_password, new_password_confirmation)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_error(:bad_claim)
    end
  end

  def update_password(conn, %{"new_password" => _new_password} = params) do
    update_password(conn, Map.put(params, "new_password_confirmation", nil))
  end

  def update_password(conn, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{ok: false})
  end
end
