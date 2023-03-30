import React, { useState } from "react";
import { useTheme } from "@mui/material/styles";
import {
  Paper,
  IconButton,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Collapse,
  Divider,
  Avatar,
  Typography,
  Tooltip,
} from "@mui/material";
import DownloadIcon from "@mui/icons-material/Download";
import MoreIcon from "@mui/icons-material/MoreHoriz";
import AndroidIcon from "@mui/icons-material/Android";
import AppleIcon from "@mui/icons-material/Apple";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import CommitIcon from "@mui/icons-material/Commit";
import UpdateIcon from "@mui/icons-material/Update";
import { useNavigate } from "react-router-dom";
import { formatDate } from "../util";

export default function PackageItem({ item, showMore = true }) {
  const theme = useTheme();
  const navigate = useNavigate();
  const [expanded, setExpanded] = useState(false);

  const handleDownloadClick = () => {
    const downloadLink = document.createElement("a");
    downloadLink.href = item.url;
    downloadLink.download = item.title;
    downloadLink.style.display = "none";
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
  };

  const handleMoreClick = () => {
    navigate(`/view/package/${item.appId}`);
  };

  const handleToggleExpand = (event) => {
    if (
      event.target.closest("button.download-btn") ||
      event.target.closest("button.more-btn")
    ) {
      return;
    }
    setExpanded(!expanded);
  };
  return (
    <div>
      <ListItem onClick={handleToggleExpand} alignItems="flex-start">
        <ListItemAvatar>
          <Avatar
            sx={{
              color: theme.palette.iconPrimary.main,
              backgroundColor: theme.palette.iconFill.main,
            }}
          >
            {item.platform === "android" ? <AndroidIcon /> : <AppleIcon />}
          </Avatar>
        </ListItemAvatar>
        <ListItemText
          primary={
            <div>
              <Typography
                sx={{ display: "inline", fontWeight: "bold" }}
                component="span"
                variant="title"
                color={theme.palette.textPrimary.main}
              >
                {`${item.title}`}
              </Typography>
              <Typography
                sx={{ display: "inline", paddingLeft: 1 }}
                component="span"
                variant="body2"
                color={theme.palette.textSecondary.main}
              >
                {`${item.appVersion} (${item.appBuild})`}
              </Typography>
            </div>
          }
          sx={{ color: theme.palette.textPrimary.main }}
          secondary={
            <React.Fragment>
              <div style={{ display: "flex", alignItems: "center" }}>
                <Tooltip title="Commit Time">
                  <CommitIcon sx={{ padding: 0.3 }} />
                </Tooltip>
                <Typography
                  sx={{ display: "inline" }}
                  component="span"
                  variant="body2"
                  color={theme.palette.textSecondary.main}
                >
                  {formatDate(item.authorAt)}
                </Typography>
              </div>
              <div style={{ display: "flex", alignItems: "center" }}>
                <Tooltip title="Upload Time">
                  <UpdateIcon sx={{ padding: 0.3 }} />
                </Tooltip>
                <Typography
                  sx={{ display: "inline" }}
                  component="span"
                  variant="body2"
                  color={theme.palette.textSecondary.main}
                >
                  {formatDate(item.updatedAt)}
                </Typography>
              </div>
              <Collapse in={expanded} timeout="auto" unmountOnExit>
                <Paper
                  elevation={0}
                  sx={{
                    marginRight: "auto",
                  }}
                >
                  <div>
                    <br />
                    {item.content.split("\n").map((line, index) => (
                      <Typography
                        key={index}
                        component="p"
                        variant="body3"
                        color={theme.palette.textSecondary.main}
                        sx={{ margin: 0 }}
                      >
                        {line}
                      </Typography>
                    ))}
                  </div>
                </Paper>
              </Collapse>
            </React.Fragment>
          }
        />
        <IconButton edge="end" sx={{ color: theme.palette.iconPrimary.main }}>
          {expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
        </IconButton>
        <IconButton
          edge="end"
          sx={{ marginLeft: "12px", color: theme.palette.iconPrimary.main }}
          onClick={handleDownloadClick}
          className="download-btn"
        >
          <DownloadIcon />
        </IconButton>
        {showMore && (
          <IconButton
            edge="end"
            sx={{ marginLeft: "12px", color: theme.palette.iconPrimary.main }}
            onClick={handleMoreClick}
            className="more-btn"
          >
            <MoreIcon />
          </IconButton>
        )}
      </ListItem>
      <Divider variant="inset" component="li" />
    </div>
  );
}
