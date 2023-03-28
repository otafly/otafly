import React, { useState } from "react";
import { Box, AppBar, Toolbar, Typography, IconButton } from "@mui/material";
import { Link } from "react-router-dom";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import NewAppMeta from "../NewAppMeta";
import AppMetaList from "../AppMetaList";

export default function Setting() {
  const [reload, setReload] = useState(false);
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
            Setting
          </Typography>
        </Toolbar>
      </AppBar>
      <Box>
        <AppMetaList reload={reload} />
        <NewAppMeta onSubmit={() => setReload(!reload)} />
      </Box>
    </div>
  );
}
