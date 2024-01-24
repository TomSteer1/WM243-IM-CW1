SELECT * from userSchema.register_user('user','user');
SELECT * from userSchema.register_user('employee','employee');
UPDATE adminSchema.users SET permissions = 3 WHERE username = 'employee';
SELECT * from userSchema.register_user('manager','manager');
UPDATE adminSchema.users SET permissions = 7 WHERE username = 'manager';
