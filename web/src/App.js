import React, { useState } from "react";
import MenuIcon from "@mui/icons-material/Menu";
import SettinsIcon from "@mui/icons-material/Settings";
import BannerIcon from "./BannerIcon";

import NewAppMeta from "./NewAppMeta";
import AppMetaList from "./AppMetaList";
import { Box, AppBar, Toolbar, IconButton, Container } from "@mui/material";

export default function App() {
  console.log("PUBLIC_URL=" + process.env.PUBLIC_URL);
  console.log("REACT_APP_PUBLIC_URL=" + process.env.REACT_APP_PUBLIC_URL);
  const [showSettings, setShowSettings] = useState(false);
  return (
    <div>
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static">
          <Toolbar>
            <IconButton color="inherit" sx={{ mr: 2 }}>
              <MenuIcon />
            </IconButton>
            <Container sx={{ width: 160 }}>
              <BannerIcon />
            </Container>
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
