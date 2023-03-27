import React from "react";
import { AppBar, Toolbar, IconButton, Container } from "@mui/material";
import { Link } from "react-router-dom";
import SettingsIcon from "@mui/icons-material/Settings";
import BannerIcon from "./BannerIcon";

export default function Home() {
  return (
    <div>
      <AppBar position="static">
        <Toolbar>
          <Container sx={{ width: 160 }}>
            <BannerIcon />
          </Container>
          <IconButton color="inherit" component={Link} to="/setting">
            <SettingsIcon />
          </IconButton>
        </Toolbar>
      </AppBar>
    </div>
  );
}
