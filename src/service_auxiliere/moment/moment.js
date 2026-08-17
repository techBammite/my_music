const express = require('express');
const app = express();
const PORT = process.env.PORT || 3004;

// Middleware pour autoriser le JSON
app.use(express.json());

app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');

    if (req.method === 'OPTIONS') {
        return res.sendStatus(204);
    }

    next();
});

function getTimeOfDayData() {
    const currentHour = new Date().getHours();
    let period = '';

    if (currentHour >= 6 && currentHour < 18) {
        period = 'matin';
    } else {
        period = 'soir';
    }

    return {
        success: true,
        service: 'moment',
        hour: currentHour,
        period: period,
        message: `Actuellement, c'est le ${period}.`
    };
}

// Route principale & route /api/time-of-day
app.get('/', (req, res) => {
    res.json(getTimeOfDayData());
});

app.get('/api/time-of-day', (req, res) => {
    res.json(getTimeOfDayData());
});

// Gestion des routes inconnues
app.use((req, res) => {
    res.status(404).json({ error: "Route non trouvée" });
});

// Démarrage local si exécuté en direct (hors Lambda)
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Microservice moment démarré sur le port ${PORT}`);
    });
}

module.exports = app;