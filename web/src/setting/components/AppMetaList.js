import React, { useState, useEffect } from "react";
import AppleIcon from "@mui/icons-material/Apple";
import AndroidIcon from "@mui/icons-material/Android";
import {
  Typography,
  Grid,
  Card,
  CardContent,
  Box,
  Stack,
  IconButton,
  Tooltip,
} from "@mui/material";
import KeyIcon from "@mui/icons-material/Key";
import * as api from "../../api";

export default function AppMetaList({ reload }) {
  const [data, setData] = useState(null);
  const [accessTokenCopied, setAccessTokenCopied] = useState(false);

  useEffect(() => {
    async function fetchData() {
      const result = await api.getAppMetas();
      setData(result);
    }
    fetchData();
  }, [reload]);

  function ItemCard({ item }) {
    return (
      <Card variant="outlined" sx={{ minWidth: 300, height: 200 }}>
        <CardContent>
          <Stack direction="row" alignItems="flex-start">
            <Typography gutterBottom variant="h5">
              {item.platform == "ios" ? <AppleIcon /> : <AndroidIcon />}
              {item.title}
            </Typography>
            <Box sx={{ flexGrow: 1 }} />
            <Tooltip
              title={
                accessTokenCopied
                  ? "Access token copied"
                  : "Click to copy access token"
              }
              onClose={() => {
                setAccessTokenCopied(false);
              }}
            >
              <IconButton
                color="inherit"
                onClick={() => {
                  navigator.clipboard.writeText(item.accessToken);
                  setAccessTokenCopied(true);
                }}
              >
                <KeyIcon />
              </IconButton>
            </Tooltip>
          </Stack>
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{
              wordWrap: "break-word",
            }}
          >
            {item.content}
          </Typography>
        </CardContent>
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
