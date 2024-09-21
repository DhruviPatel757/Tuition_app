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

const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
});

const taskSchema = new mongoose.Schema({
    title: { type: String, required: true },
    assignedTo: { type: String, required: true }, 
    group: { type: String, required: true }, 
    createdAt: { type: Date, default: Date.now },
});

const feeSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    paid: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model('User', userSchema);
const Task = mongoose.model('Task', taskSchema);
const Fee = mongoose.model('Fee', feeSchema);

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
        res.status(200).send({ message: 'Login successful!', isAdmin: (username === 'admin'), userId: user._id });
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
    const users = await User.find({}, 'username _id'); 
    res.status(200).send(users);
});

app.post('/addFees', async (req, res) => {
    const { userId, amount } = req.body;
    const newFee = new Fee({ userId, amount });
    await newFee.save();
    res.status(201).send({ message: 'Fees added successfully!' });
});
app.post('/payFees/:feeId', async (req, res) => {
    const { feeId } = req.params;
    try {
        const fee = await Fee.findById(feeId);
        if (!fee) {
            return res.status(404).send({ message: 'Fee not found' });
        }
        fee.paid = true;
        await fee.save();
        res.status(200).send({ message: 'Fee marked as paid' });
    } catch (error) {
        res.status(500).send({ message: 'Error marking fee as paid' });
    }
});

app.put('/updateFee/:feeId', async (req, res) => {
    const { feeId } = req.params;
    const { paid } = req.body;

    try {
        const fee = await Fee.findById(feeId);
        if (!fee) {
            return res.status(404).send({ message: 'Fee not found' });
        }
        fee.paid = paid;
        await fee.save();
        res.status(200).send({ message: 'Fee updated successfully!' });
    } catch (error) {
        res.status(500).send({ message: 'Error updating fee' });
    }
});

app.get('/fees/:userId', async (req, res) => {
    const { userId } = req.params;
    const fees = await Fee.find({ userId }).populate('userId', 'username');
    res.status(200).send(fees);
});

app.get('/fees', async (req, res) => {
    const fees = await Fee.find().populate('userId', 'username');
    res.status(200).send(fees);
});

app.get('/admin/tasks', async (req, res) => {
    try {
        const tasks = await Task.find().populate('assignedTo', 'username'); 
        res.status(200).send(tasks);
    } catch (error) {
        res.status(500).send({ message: 'Error fetching tasks' });
    }
});

app.get('/admin/users', async (req, res) => {
    try {
        const users = await User.find({}, 'username _id'); 
        res.status(200).send(users);
    } catch (error) {
        res.status(500).send({ message: 'Error fetching users' });
    }
});

app.get('/admin/fees', async (req, res) => {
    try {
      const fees = await Fee.find().populate('userId', 'username');
      res.status(200).send(fees);
    } catch (error) {
      res.status(500).send({ message: 'Error fetching fees' });
    }
  });

  app.delete('/tasks/:taskId', async (req, res) => {
    try {
      const { taskId } = req.params;
      const deletedTask = await Task.findByIdAndDelete(taskId);
      if (!deletedTask) {
        return res.status(404).send({ message: 'Task not found' });
      }
      res.status(200).send({ message: 'Task deleted successfully' });
    } catch (error) {
      res.status(500).send({ message: 'Error deleting task' });
    }
  });

  app.delete('/fees/:feeId', async (req, res) => {
    try {
      const { feeId } = req.params;
      const deletedFee = await Fee.findByIdAndDelete(feeId);
      if (!deletedFee) {
        return res.status(404).send({ message: 'Fee not found' });
      }
      res.status(200).send({ message: 'Fee deleted successfully' });
    } catch (error) {
      res.status(500).send({ message: 'Error deleting fee' });
    }
  });
  


app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});