// MongoDB initialization script
db = db.getSiblingDB('travelmemory');

// Create a user for the application
db.createUser({
  user: 'appuser',
  pwd: 'apppassword',
  roles: [
    {
      role: 'readWrite',
      db: 'travelmemory'
    }
  ]
});

// Create some initial collections
db.createCollection('trips');
db.createCollection('users');

print('MongoDB initialization completed');
