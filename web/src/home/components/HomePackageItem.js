import React from "react";

import { IconButton, ListItem, ListItemAvatar, ListItemText, Divider } from '@mui/material';
import Avatar from '@mui/material/Avatar';
import DownloadIcon from '@mui/icons-material/Download';
import MoreIcon from '@mui/icons-material/MoreHoriz';
import AndroidIcon from "@mui/icons-material/Android";
import AppleIcon from "@mui/icons-material/Apple";
import Typography from '@mui/material/Typography';

export default function HomePackageItem({ item }) {

  const handleDownloadClick = () => {
    console.log('download');
  };

  const handleMoreClick = () => {
    console.log('more');
  };

  return (
    <div>
      <ListItem
        alignItems="flex-start"
        secondaryAction={
          <React.Fragment>
            <IconButton edge="end" sx={{ marginRight: '8px' }} onClick={handleDownloadClick}>
              <DownloadIcon />
            </IconButton>
            <IconButton edge="end" onClick={handleMoreClick}>
              <MoreIcon />
            </IconButton>
          </React.Fragment>
        }
      >
        <ListItemAvatar>
          <Avatar>
            {item.platform === 'android' ? <AndroidIcon /> : <AppleIcon />}
          </Avatar>
        </ListItemAvatar>
        <ListItemText
          primary={item.title}
          secondary={
            <React.Fragment>
              <Typography
                sx={{ display: 'inline' }}
                component="span"
                variant="body2"
                color="text.secondary"
              >
                {`${item.appVersion}(${item.appBuild})`}
              </Typography>
              <br />
              <Typography
                sx={{ display: 'inline' }}
                component="span"
                variant="body2"
                color="text.blueGrey"
              >
                {formatDate(item.createdAt)}
              </Typography>
            </React.Fragment>
          }
        />
      </ListItem>
      <Divider variant="inset" component="li" />
    </div>
  );
}

function formatDate(dateString) {
  const date = new Date(dateString);

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}