import React, { useState } from "react";
import MenuIcon from "@mui/icons-material/Menu";
import SettinsIcon from "@mui/icons-material/Settings";
import NewAppMeta from "./NewAppMeta";
import AppMetaList from "./AppMetaList";
import { Box, AppBar, Toolbar, IconButton, Typography } from "@mui/material";

export default function App() {
  const [showSettings, setShowSettings] = useState(false);
  return (
    <div>
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static">
          <Toolbar>
            <IconButton color="inherit" sx={{ mr: 2 }}>
              <MenuIcon />
            </IconButton>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Otafly
            </Typography>
            <IconButton color="inherit" onClick={() => setShowSettings(true)}>
              <SettinsIcon />
            </IconButton>
          </Toolbar>
        </AppBar>
      </Box>
      {showSettings ? <SettingPage /> : <Box />}
    </div>
  );
}

function SettingPage() {
  const [reload, setReload] = useState(false);
  return (
    <Box>
      <AppMetaList reload={reload} />
      <NewAppMeta onSubmit={() => setReload(!reload)} />
    </Box>
  );
}
