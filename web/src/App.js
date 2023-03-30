import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./home/Home";
import Setting from "./setting/Setting";
import PackageList from "./package/PackageList";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/view/setting" element={<Setting />} />
        <Route path="/view/package/:id" element={<PackageList />} />
      </Routes>
    </BrowserRouter>
  );
}
