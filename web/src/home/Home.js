import React, { useState, useEffect } from "react";
import { AppBar, Toolbar, IconButton, Container, List } from "@mui/material";
import { Link } from "react-router-dom";
import SettingsIcon from "@mui/icons-material/Settings";
import BannerIcon from "./components/BannerIcon";
import PackageItem from "../common/components/PackageItem";
import * as api from "../api";

export default function Home({ reload }) {
  const [data, setData] = useState(null);
  useEffect(() => {
    async function fetchData() {
      const result = await api.getLatestPackages();
      setData(result);
    }
    fetchData();
  }, [reload]);

  const packageItems = data
    ? data.items.map((item, index) => (
        <PackageItem key={index} item={item} showMore={true} />
      ))
    : null;

  return (
    <div>
      <AppBar position="static">
        <Toolbar>
          <Container sx={{ width: 160 }}>
            <BannerIcon />
          </Container>
          <IconButton color="inherit" component={Link} to="/view/setting">
            <SettingsIcon />
          </IconButton>
        </Toolbar>
      </AppBar>
      <List>{packageItems}</List>
    </div>
  );
}
