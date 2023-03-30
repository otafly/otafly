import React, { useState } from "react";
import { Box, AppBar, Toolbar, Typography, IconButton } from "@mui/material";
import { Link } from "react-router-dom";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import NewAppMeta from "./components/NewAppMeta";
import AppMetaList from "./components/AppMetaList";
import Login from "../Login";
import * as api from "../api";

export default function Setting() {
  const [reload, setReload] = useState(false);
  const isAdmin = api.isAdmin();
  return (
    <div>
      <AppBar position="static">
        <Toolbar>
          <IconButton color="inherit" component={Link} to="/">
            <ChevronLeftIcon />
          </IconButton>
          <Typography
            variant="h5"
            fontWeight="bold"
            align="center"
            sx={{ flexGrow: 1 }}
          >
            {isAdmin ? "Setting" : "Login"}
          </Typography>
        </Toolbar>
      </AppBar>
      <Box>
        {isAdmin ? (
          <div>
            <AppMetaList reload={reload} />
            <NewAppMeta onSubmit={() => setReload(!reload)} />
          </div>
        ) : (
          <Login onSubmit={() => setReload(!reload)} />
        )}
      </Box>
    </div >
  );
}
