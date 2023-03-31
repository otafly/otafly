import React, { useState } from "react";
import { Button, TextField } from "@mui/material";
import * as api from "./api";
import { Stack } from "@mui/system";

export default function Login({ onSubmit }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(false);

  const handleSubmit = (event) => {
    event.preventDefault();
    submit();
  };

  async function submit() {
    try {
      await api.getUser(username, password);
      onSubmit();
    } catch (error) {
      setError(true);
    }
  }
  const isAnyEmpty =
    !username || username.trim() === "" || !password || password.trim() === "";

  return (
    <Stack alignItems="center" marginTop={2}>
      <Stack minWidth={400} spacing={2}>
        <TextField
          autoFocus
          margin="dense"
          id="username"
          label="Username"
          variant="standard"
          color="textPrimary"
          onChange={(event) => {
            setUsername(event.target.value);
          }}
        />
        <TextField
          margin="dense"
          id="password"
          label="Password"
          variant="standard"
          type="password"
          autoComplete="current-password"
          color="textPrimary"
          onChange={(event) => {
            setPassword(event.target.value);
          }}
        />
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={isAnyEmpty}
        >
          Login
        </Button>
      </Stack>
    </Stack>
  );
}
