import React from "react";
import { useParams, Link } from "react-router-dom";
import { Box, AppBar, Toolbar, Typography, IconButton } from "@mui/material";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import * as api from "../api";

export default function PackageList() {
    const { title, id } = useParams();
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

        </div>
    );
}