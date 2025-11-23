// src/components/DashboardButton.jsx

import React from 'react';

function DashboardButton({ label, onClick }) {
  return (
    <button className="dashboard-button" onClick={onClick}>
      {label}
    </button>
  );
}

export default DashboardButton;