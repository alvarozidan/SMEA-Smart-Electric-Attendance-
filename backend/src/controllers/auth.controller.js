const authService = require("../services/auth.service");

async function login(req, res, next){
    try {
        const { email, password } = req.body;
        if (!email || !password){
            return res.status(400).json({ message: "Email dan password harus diisi"});
        }
        const result = await authService.login(email, password);
        res.status(200).json(result);
    } catch (err){
        next(err);
    }
}

async function loginStudent(req, res, next) {
    try {
        const { nis, password } = req.body;
        if (!nis || !password) {
            return res.status(400).json({ message: "NIS dan password harus diisi" });
        }

        const result = await authService.loginStudent(nis, password);
        res.status(200).json(result);
    } catch (err) {
        next(err);
    }
}

async function changePassword(req, res, next){
    try {
        const { oldPassword, newPassword } = req.body;
        if (!oldPassword || !newPassword){
            return res.status(400).json({ message: "Password lama dan baru harus diisi"});
        }

        await authService.changePassword(req.user.id, oldPassword, newPassword);
        res.status(200).json({ message: "Password berhasil diubah" });
    } catch (err){
        next(err);
    }
}

async function refresh(req, res, next){
    try {
        const { refreshToken } = req.body;
        if (!refreshToken){
            return res.status(400).json({ message: "Refresh token harus diisi"});
        }

        const result = await authService.refresh(refreshToken);
        res.status(200).json(result);
    } catch (err){
        next(err);
    }
}

async function logout(req, res, next){
    try {
        const { refreshToken } = req.body;
        if (!refreshToken){
            return res.status(400).json({ message: "Refresh token harus diisi"});
        }

        await authService.logout(refreshToken);
        res.status(200).json({ message: "Logout berhasil" });
    } catch (err){
        next(err);
    }
}

module.exports = { login, loginStudent, changePassword, refresh, logout };