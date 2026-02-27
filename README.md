# DermatoLab - AI Skin Disease Detection App

**An intelligent mobile app that helps you check your skin health using your phone's camera.**

Built with Flutter and TensorFlow Model and OpenAI

---

## What is this?

DermatoLab is a mobile app that uses artificial intelligence to analyze photos of your skin and detect potential skin conditions. Think of it as having a dermatology assistant in your pocket - it's not a replacement for a real doctor, but it can help you understand if you should get something checked out.

The app uses a machine learning model trained on thousands of medical images to identify 7 common skin conditions with pretty good accuracy. It also connects you with nearby dermatologists if you need professional help.

## 🎥 Demo Video

[![Watch the Demo](https://img.youtube.com/vi/WzXpIxYj2mc/0.jpg)](https://youtube.com/shorts/WzXpIxYj2mc)

---

## Why I built this

Skin problems are super common, but lots of people ignore them because they're not sure if it's serious enough to see a doctor. This app gives you a quick first opinion, so you can make better decisions about your health.

Plus, finding a dermatologist can be a pain. The app shows you nearby specialists on a map, with ratings and contact info.

---

## What it can detect

The app can identify these 7 skin conditions:

**Cancer-related:**
- Melanoma - the most dangerous type of skin cancer
- Basal cell carcinoma - most common skin cancer, usually treatable
- Actinic keratoses - pre-cancerous spots

**Non-cancerous:**
- Melanocytic nevi - regular moles
- Benign keratosis - harmless skin growths
- Dermatofibroma - small harmless bumps
- Vascular lesions - blood vessel issues in the skin

The model is about 85-92% accurate overall, which is pretty good for an AI, but definitely not perfect. That's why you should always see a real doctor for anything concerning.

---

## How it works

**Step 1: Take a photo**
Open the app and point your camera at the skin area you want to check. The app helps you get a good shot by showing you if you're too close, too far, or if the image is blurry.

**Step 2: AI analysis**
The app runs the image through a machine learning model that's been trained on 10,000+ medical images. It takes just a few seconds.

**Step 3: Get results**
You'll see what the AI thinks it is, how confident it is in that assessment, and a risk level (low, moderate, high, or very high).

**Step 4: AI recommendations**
Click "Get AI Analysis" to get personalized advice from GPT-4 about what you should do next, home care tips, and when you should see a doctor.

**Step 5: Find help**
If needed, the app shows you nearby dermatologists on a map with ratings, so you can book an appointment.

---

## Key features

**Smart camera**
The camera interface helps you take the best possible photo with real-time guidance about distance, lighting, and focus.

**Risk assessment**
Not just "here's what it might be" - the app tells you how serious it could be and what action to take.

**AI chat assistant**
Ask questions and get detailed, personalized recommendations powered by OpenAI's GPT-4.

**Doctor finder**
Find and contact dermatologists near you without leaving the app.

**History tracking**
Save your scans and track changes over time to see if things are getting better or worse.

**Works offline (mostly)**
The disease detection works completely offline. You only need internet for the AI chat and doctor finder features.

---

## Getting started

**What you need:**
- A computer with Flutter installed
- An Android device or emulator
- About 30 minutes to set everything up

**Quick setup:**

1. Clone this repository
```bash
git clone https://github.com/NadimOvi/DermatoLab-AI_Skin_Analysis.git
cd DermatoLab-AI_Skin_Analysis/dermatolab
```

2. Install dependencies
```bash
flutter pub get
```

3. Create a `.env` file in the project root and add your API keys
```
OPENAI_API_KEY=your-key-here
GOOGLE_MAPS_API_KEY=your-key-here
```

Don't have API keys? Here's where to get them:
- OpenAI: https://platform.openai.com/api-keys (for the AI chat)
- Google Maps: https://console.cloud.google.com (for finding doctors)

4. Run the app
```bash
flutter run
```

That's it! The app should launch on your device.

---

## About the AI model

**How I trained it:**

The model is based on MobileNetV2, which is a popular architecture for mobile apps. I trained it on the HAM10000 dataset - a collection of 10,015 dermatology images from real patients.

The original dataset was very imbalanced (67% of images were just regular moles), so I had to balance it by oversampling the rare conditions. This gave the model a fair chance to learn all 7 conditions properly.

**Training process:**
- Phase 1: 80 epochs with frozen base layers
- Phase 2: 40 more epochs with fine-tuning
- Total time: About 4-5 hours on a GPU
- Final size: 3.15 MB (small enough for phones)

**Performance:**
- Overall accuracy: 85-92%
- Works in real-time on phones
- No internet needed for detection


---

## Project structure

Here's how the code is organized:

**dermatolab/** - The main Flutter app
- `lib/screens/` - All the app screens (camera, results, doctor list, etc.)
- `lib/blocs/` - State management using BLoC pattern
- `lib/models/` - Data models for results, diseases, doctors
- `lib/repositories/` - Where the ML model lives and runs
- `lib/utils/` - Helper functions, including the OpenAI integration
- `assets/models/` - The TensorFlow Lite model file

**dermatolab-training/** - ML training pipeline
- `scripts/train_model.py` - Main training script
- `data/` - Where you put the dataset
- `models/` - Saved models and checkpoints
- `results/` - Training graphs and metrics

**docs/** - Documentation and screenshots

It's pretty straightforward. The app follows Flutter best practices with BLoC for state management and a clean separation between UI, logic, and data.

---

## Tech stack

**Frontend:**
- Flutter 3.x for the UI
- BLoC pattern for managing app state
- Camera plugin for taking photos
- Google Maps for showing doctors

**AI/ML:**
- TensorFlow Lite for running the model on-device
- OpenAI GPT-4 for the chat assistant
- Python + TensorFlow 2.10 for training

**Other stuff:**
- HTTP for API calls
- flutter_dotenv for managing API keys securely

---

## Common questions

**Is this as good as seeing a real dermatologist?**
No. Not even close. This is meant to help you decide if you should see a doctor, not replace one.

**Does it work offline?**
The disease detection works completely offline. The AI chat and doctor finder need internet.

**What happens to my photos?**
They stay on your device. The app doesn't upload anything to a server. The only data that leaves your phone is when you use the AI chat feature.

**Can I use this on iPhone?**
The code supports iOS, but I haven't fully tested it yet. Android works great though.

**How accurate is it really?**
About 85-92% overall. Some conditions are easier to detect than others. Vascular lesions hit 94% accuracy, while benign keratosis is closer to 78%.

**What if it's wrong?**
That's why the app shows you a confidence score and risk level. If it's only 60% sure, you should definitely see a doctor. Even at 90%, you should still get it checked by a professional.

---

## Things to know

**Medical disclaimer:**
This app is for educational purposes only. It's not medical advice and it's not a diagnostic tool. If you're worried about something on your skin, see a real doctor. Seriously.

---

## Want to contribute?

I'd love help making this better! Here's how you can contribute:

**Report bugs:** If something breaks, open an issue with details about what happened

**Suggest features:** Have an idea? Open an issue and let's discuss it

**Improve the model:** Better training data or techniques? PRs welcome

**Fix bugs:** Check the issues tab for things that need fixing

**Add translations:** The app is only in English right now

Just fork the repo, make your changes, and open a pull request. Keep the code clean and add comments where things might be confusing.

---

## Roadmap

Things I'm planning to add:

- Support for more skin conditions
- Better handling of different skin tones
- Medication tracking and reminders
- Export reports as PDF
- User accounts to sync across devices
- Support for more languages
- iOS testing and release

---


## Contact

Built by Nadim Ovi

- GitHub: github.com/NadimOvi
- Project: github.com/NadimOvi/DermatoLab-AI_Skin_Analysis

Found a bug? Have a question? Open an issue on GitHub.


---

That's pretty much it. The app isn't perfect, but it's a start. If you have ideas to make it better, I'm all ears.

Thanks for checking it out!
