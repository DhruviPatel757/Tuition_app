const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 6787;

app.use(cors());
app.use(bodyParser.json());

mongoose.connect('mongodb+srv://dhruvi010804:passwords@vaidyatutorials.3in64ay.mongodb.net/?retryWrites=true&w=majority&appName=vaidyatutorials', {
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.log(err));

// User Schema
const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
});

// Task Schema
const taskSchema = new mongoose.Schema({
    title: { type: String, required: true },
    assignedTo: { type: String, required: true }, 
    group: { type: String, required: true }, 
    createdAt: { type: Date, default: Date.now },
});

// Fees Schema
const feeSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model('User', userSchema);
const Task = mongoose.model('Task', taskSchema);
const Fee = mongoose.model('Fee', feeSchema);

// Add User Endpoint
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

// Login Endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if (user && user.password === password) {
        res.status(200).send({ message: 'Login successful!', isAdmin: (username === 'admin'), userId: user._id });
    } else {
        res.status(401).send({ message: 'Invalid username or password' });
    }
});

// Add Task Endpoint
app.post('/addTask', async (req, res) => {
    const { title, assignedTo, group } = req.body;
    const newTask = new Task({ title, assignedTo, group });
    await newTask.save();
    res.status(201).send({ message: 'Task added successfully!' });
});

// Get Tasks Endpoint
app.get('/tasks', async (req, res) => {
    const { group } = req.query; 
    const tasks = group === 'All' ? await Task.find() : await Task.find({ group });
    res.status(200).send(tasks);
});

// Get Users Endpoint
app.get('/users', async (req, res) => {
    const users = await User.find({}, 'username _id'); // Include user ID
    res.status(200).send(users);
});

// Add Fees Endpoint
app.post('/addFees', async (req, res) => {
    const { userId, amount } = req.body;
    const newFee = new Fee({ userId, amount });
    await newFee.save();
    res.status(201).send({ message: 'Fees added successfully!' });
});

// Get Fees for a User Endpoint
app.get('/fees/:userId', async (req, res) => {
    const { userId } = req.params;
    const fees = await Fee.find({ userId }).populate('userId', 'username');
    res.status(200).send(fees);
});

// Get all fees for admin view (optional)
app.get('/fees', async (req, res) => {
    const fees = await Fee.find().populate('userId', 'username');
    res.status(200).send(fees);
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});