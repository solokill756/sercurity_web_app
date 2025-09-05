u1 = User.create!(email: "alice@example.com", password: "Password!23", role: "user")
u2 = User.create!(email: "bob@example.com",   password: "Password!23", role: "admin")

e1 = Event.create!(title: "HCMC Night Fest",
                   description: "Party at District 1",
                   location: "Q1",
                   starts_at: 1.week.from_now)

Comment.create!(event: e1, user: u1, content: "Hẹn gặp nhé!")