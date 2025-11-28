import React, { useState, useEffect } from 'react';

function App() {
  const [instances, setInstances] = useState([]);

  useEffect(() => {
    fetch('/api/instances')
      .then(res => res.json())
      .then(data => setInstances(data));
  }, []);

  const createInstance = () => {
    fetch('/api/instances', { method: 'POST' })
      .then(res => res.json())
      .then(data => {
        setInstances([...instances, data]);
      });
  };

  const deleteInstance = (id) => {
    fetch(`/api/instances/${id}`, { method: 'DELETE' })
      .then(() => {
        setInstances(instances.filter(instance => instance.id !== id));
      });
  };

  return (
    <div>
      <h1>Mitmproxy Instances</h1>
      <button onClick={createInstance}>Create Instance</button>
      <ul>
        {instances.map(instance => (
          <li key={instance.id}>
            Instance {instance.id} - {instance.status} - IP: {instance.public_ip}:8080
            <button onClick={() => deleteInstance(instance.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
