import React, { useState, useEffect } from "react";
import AppleIcon from "@mui/icons-material/Apple";
import AndroidIcon from "@mui/icons-material/Android";
import {
  Typography,
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
      <Card
        variant="outlined"
        sx={{
          width: 300,
          height: 200,
          margin: 2,
        }}
      >
        <CardContent>
          <Stack direction="row" alignItems="flex-start" spacing={1}>
            {item.platform == "ios" ? <AppleIcon /> : <AndroidIcon />}
            <Typography variant="h6">{item.title}</Typography>
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
    <Box
      sx={{
        display: "flex",
        flexWrap: "wrap",
        margin: 2,
      }}
    >
      {data != null &&
        data.items.map((item) => <ItemCard key={item.id} item={item} />)}
    </Box>
  );
}
