// src/components/DashboardCard.jsx

import React from 'react';

function DashboardCard({ title, value, icon, color }) {
  const cardStyle = {
    backgroundColor: color || '#85C744', // Usa el color pasado o un verde por defecto
  };

  return (
    <div className="dashboard-card" style={cardStyle}>
      <div className="card-icon">{icon}</div>
      <div className="card-content">
        <p className="card-title">{title}</p>
        <h3 className="card-value">{value}</h3>
      </div>
    </div>
  );
}

export default DashboardCard;