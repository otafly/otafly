import { red } from "@mui/material/colors";
import { createTheme } from "@mui/material/styles";

// A custom theme for this app
const theme = createTheme({
  palette: {
    background: {
      default: "#EEEEEE",
    },
    primary: {
      main: "#658864",
    },
    secondary: {
      main: "#19857b",
    },
    textPrimary: {
      main: "#292524",
    },
    textSecondary: {
      main: "#78716c",
    },
    error: {
      main: "#bc6c25",
    },
  },
});

export default theme;
