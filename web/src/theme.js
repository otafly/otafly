import { createTheme } from "@mui/material/styles";

// A custom theme for this app
const theme = createTheme({
  palette: {
    background: {
      default: "#FFFFFF",
    },
    primary: {
      main: "#F2F2F2",
    },
    secondary: {
      main: "#19857b",
    },
    iconPrimary: {
      main: "#5C5C5C",
    },
    iconFill: {
      main: "#F5F5F5",
    },
    textPrimary: {
      main: "#5C5C5C",
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
