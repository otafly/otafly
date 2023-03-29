import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { AppBar, Toolbar, Typography, IconButton, List } from "@mui/material";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import PackageItem from "../common/components/PackageItem";
import * as api from "../api";

export default function PackageList({ reload }) {
  const { title, id } = useParams();
  const [data, setData] = useState(null);
  useEffect(() => {
    async function fetchData() {
      const result = await api.getPackage(id);
      setData(result);
    }
    fetchData();
  }, [reload]);

  const packageItems = data
    ? data.items.map((item, index) => (
        <PackageItem key={index} item={item} showMore={false} />
      ))
    : null;

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
            {title}
          </Typography>
        </Toolbar>
      </AppBar>
      <List>{packageItems}</List>
    </div>
  );
}
