import React from "react";
import { useTheme } from "@mui/material/styles";
import {
  IconButton,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Collapse,
  Divider,
  Avatar,
  Typography,
} from "@mui/material";
import DownloadIcon from "@mui/icons-material/Download";
import MoreIcon from "@mui/icons-material/MoreHoriz";
import AndroidIcon from "@mui/icons-material/Android";
import AppleIcon from "@mui/icons-material/Apple";
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';

import { useNavigate } from 'react-router-dom';
import { formatDate } from "../util";

export default function PackageItem({ item, showMore = true }) {
  const navigate = useNavigate();
  const theme = useTheme();

  const handleDownloadClick = () => {
    const downloadLink = document.createElement('a');
    downloadLink.href = item.url;
    downloadLink.download = item.title;
    downloadLink.style.display = 'none';
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
  };

  const handleMoreClick = () => {
    navigate(`/view/package/${item.title}/${item.appId}`);
  };

  const [open, setOpen] = React.useState(false);
  const handleClickExpand = () => {
    setOpen(!open);
  };

  return (
    <div>
      <ListItem
        alignItems="flex-start"
        secondaryAction={
          <React.Fragment>
            <IconButton
              edge="end"
              sx={{ color: theme.palette.primary.main }}
              onClick={handleClickExpand}
            >
              {open ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            </IconButton>

            <IconButton
              edge="end"
              sx={{ marginLeft: "12px", color: theme.palette.primary.main }}
              onClick={handleDownloadClick}
            >
              <DownloadIcon />
            </IconButton>
            {showMore && (
              <IconButton
                edge="end"
                sx={{ marginLeft: "12px", color: theme.palette.primary.main }}
                onClick={handleMoreClick}>
                <MoreIcon />
              </IconButton>
            )}
          </React.Fragment>
        }
      >
        <ListItemAvatar>
          <Avatar sx={{ backgroundColor: theme.palette.primary.main }}>
            {item.platform === "android" ? <AndroidIcon /> : <AppleIcon />}
          </Avatar>
        </ListItemAvatar>
        <ListItemText
          primary={<Typography
            sx={{ display: "inline", fontWeight: 'bold' }}
            component="span"
            variant="title"
            color={theme.palette.textPrimary.main}
          >
            {`${item.title}`}
          </Typography>}
          sx={{ color: theme.palette.textPrimary.main }}
          secondary={
            <React.Fragment>
              <Typography
                sx={{ display: "inline" }}
                component="span"
                variant="body2"
                color={theme.palette.textSecondary.main}
              >
                {`${item.appVersion}(${item.appBuild})`}
              </Typography>
              <br />
              <Typography
                sx={{ display: "inline" }}
                component="span"
                variant="body2"
                color={theme.palette.textSecondary.main}
              >
                {formatDate(item.createdAt)}
              </Typography>
              <Collapse in={open} timeout="auto" unmountOnExit>
                <Typography
                  sx={{ display: "inline" }}
                  component="span"
                  variant="body3"
                  color={theme.palette.textSecondary.main}
                >
                  <br />
                  {item.content}
                </Typography>
              </Collapse>
            </React.Fragment>
          }
        />
      </ListItem>
      <Divider variant="inset" component="li" />
    </div >
  );
}