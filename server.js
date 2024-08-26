const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

mongoose.connect('mongodb+srv://dhruvi010804:passwords@vaidyatutorials.3in64ay.mongodb.net/?retryWrites=true&w=majority&appName=vaidyatutorials', {
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.log(err));

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
});

const User = mongoose.model('User', userSchema);

const taskSchema = new mongoose.Schema({
    title: { type: String, required: true },
    assignedTo: { type: String, required: true }, 
    group: { type: String, required: true }, 
    createdAt: { type: Date, default: Date.now },
});

const Task = mongoose.model('Task', taskSchema);

app.post('/addUser', async (req, res) => {
    const { username, password } = req.body;
    const existingUser = await User.findOne({ username });
    if (existingUser) {
        return res.status(400).send({ message: 'User already exists' });
    }
    const newUser = new User({ username, password });
    await newUser.save();
    res.status(201).send({ message: 'User added successfully!' });
});

app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if (user && user.password === password) {
        res.status(200).send({ message: 'Login successful!', isAdmin: (username === 'admin') });
    } else {
        res.status(401).send({ message: 'Invalid username or password' });
    }
});

app.post('/addTask', async (req, res) => {
    const { title, assignedTo, group } = req.body;
    const newTask = new Task({ title, assignedTo, group });
    await newTask.save();
    res.status(201).send({ message: 'Task added successfully!' });
});

app.get('/tasks', async (req, res) => {
    const { group } = req.query; 
    const tasks = group === 'All' ? await Task.find() : await Task.find({ group });
    res.status(200).send(tasks);
});

app.get('/users', async (req, res) => {
    const users = await User.find({}, 'username'); 
    res.status(200).send(users);
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});