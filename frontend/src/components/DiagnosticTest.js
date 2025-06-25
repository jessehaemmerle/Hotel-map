import React, { useEffect, useState } from 'react';

const DiagnosticTest = () => {
  const [results, setResults] = useState({});
  
  useEffect(() => {
    const runDiagnostics = async () => {
      const diagResults = {
        timestamp: new Date().toISOString(),
        envVar: process.env.REACT_APP_BACKEND_URL,
        envVarType: typeof process.env.REACT_APP_BACKEND_URL,
        localStorage: localStorage.getItem('token'),
        userAgent: navigator.userAgent,
      };

      // Test API connectivity
      try {
        const response = await fetch(`${process.env.REACT_APP_BACKEND_URL}/api/hotels`);
        diagResults.apiTest = {
          status: response.status,
          ok: response.ok,
          url: response.url
        };
      } catch (error) {
        diagResults.apiTest = {
          error: error.message
        };
      }

      setResults(diagResults);
    };

    runDiagnostics();
  }, []);

  return (
    <div style={{ padding: '20px', fontFamily: 'monospace', backgroundColor: '#f5f5f5' }}>
      <h2>🔍 React Environment Diagnostics</h2>
      <pre style={{ backgroundColor: 'white', padding: '15px', border: '1px solid #ccc' }}>
        {JSON.stringify(results, null, 2)}
      </pre>
    </div>
  );
};

export default DiagnosticTest;