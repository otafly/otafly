import React, { useState, useEffect } from "react";
import AddIcon from "@mui/icons-material/Add";
import AppleIcon from "@mui/icons-material/Apple";
import AndroidIcon from "@mui/icons-material/Android";
import {
  Fab,
  Button,
  TextField,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  ToggleButton,
  ToggleButtonGroup,
  Box,
  Snackbar,
  Alert,
} from "@mui/material";
import * as api from "./api";

export default function NewAppMeta(props) {
  const [open, setOpen] = useState(false);
  const [formData, setFormData] = useState({});
  const [error, setError] = useState(false);

  const handleChange = (event) => {
    setFormData({ ...formData, [event.target.id]: event.target.value });
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    submit();
  };

  const handleClickOpen = () => {
    setOpen(true);
  };

  const handleClose = () => {
    setFormData({});
    setOpen(false);
  };

  async function submit() {
    try {
      await api.createAppMeta(formData);
      handleClose();
      props.onSubmit();
    } catch (error) {
      setError(true);
    }
  }

  const handleSnackBarClose = (event, reason) => {
    if (reason === "clickaway") {
      return;
    }
    setError(false);
  };

  const styles = {
    fab: {
      position: "fixed",
      bottom: "32px",
      right: "32px",
    },
  };

  const title = formData["title"];
  const isTitleEmpty = !title || title.trim() === "";

  return (
    <div>
      <Fab color="primary" style={styles.fab} onClick={handleClickOpen}>
        <AddIcon />
      </Fab>
      <Dialog open={open} onClose={handleClose}>
        <DialogTitle>Create a new app</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            id="title"
            label="Title"
            fullWidth
            variant="standard"
            onChange={handleChange}
          />
          <TextField
            margin="dense"
            id="content"
            label="Content"
            fullWidth
            variant="standard"
            multiline
            rows={4}
            onChange={handleChange}
          />
          <Box
            sx={{
              width: 400,
              height: 30,
            }}
          />
          <PlatformSelector id="platform" value="ios" onChange={handleChange} />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={isTitleEmpty}
          >
            Create
          </Button>
        </DialogActions>
      </Dialog>
      <Snackbar
        open={error}
        autoHideDuration={3000}
        onClose={handleSnackBarClose}
      >
        <Alert
          onClose={handleSnackBarClose}
          severity="error"
          sx={{ width: "100%" }}
        >
          Something went wrong!
        </Alert>
      </Snackbar>
    </div>
  );
}

function PlatformSelector(props) {
  const { id, onChange, value, ...other } = props;
  const [platform, setPlatform] = useState(props.value);

  const handleOnChange = (event, value) => {
    if (value == null) {
      return;
    }
    setPlatform(value);
    props.onChange({
      target: {
        id: props.id,
        value: value,
      },
    });
  };

  useEffect(() => {
    props.onChange({
      target: {
        id: props.id,
        value: props.value,
      },
    });
  }, []);

  return (
    <ToggleButtonGroup
      color="primary"
      value={platform}
      exclusive
      onChange={handleOnChange}
      {...other}
    >
      <ToggleButton value="ios">
        <AppleIcon />
      </ToggleButton>
      <ToggleButton value="android">
        <AndroidIcon />
      </ToggleButton>
    </ToggleButtonGroup>
  );
}
