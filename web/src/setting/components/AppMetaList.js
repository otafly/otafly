import React, { useState, useEffect } from "react";
import AppleIcon from "@mui/icons-material/Apple";
import AndroidIcon from "@mui/icons-material/Android";
import {
  Typography,
  Grid,
  Card,
  CardContent,
  CardActionArea,
  Box,
} from "@mui/material";
import * as api from "../../api";

export default function AppMetaList({ reload }) {
  const [data, setData] = useState(null);

  useEffect(() => {
    async function fetchData() {
      const result = await api.getAppMetas();
      setData(result);
    }
    fetchData();
  }, [reload]);

  function ItemCard({ item }) {
    return (
      <Card variant="outlined" sx={{ width: 300, height: 200 }}>
        <CardActionArea>
          <CardContent>
            <Typography gutterBottom variant="h5">
              {item.platform == "ios" ? <AppleIcon /> : <AndroidIcon />}
              {item.title}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{
                wordWrap: "break-word"
            }}>
              {item.content}
            </Typography>
            <Box width={1000} height={1000} />
          </CardContent>
        </CardActionArea>
      </Card>
    );
  }

  return (
    <Grid container spacing={2} padding={2}>
      {data != null &&
        data.items.map((item) => (
          <Grid key={item.id} mx={2} my={2}>
            <ItemCard item={item} />
          </Grid>
        ))}
    </Grid>
  );
}
