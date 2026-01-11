from fastapi import FastAPI, File, UploadFile
from PIL import Image
import torch
import torchvision.transforms as transforms
import io

app = FastAPI(title="Skin Disease Classification API")

# ===== Load Model =====
model = torch.jit.load("model.pt", map_location="cpu")
model.eval()

# ===== Class Names (sesuaikan) =====
classes = ["Acne", "Carcinoma", "Eczema", "Keratosis", "Milia", "Normal", "Other", "Rosacea"]


# ===== Preprocessing =====
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

# ===== Endpoint =====
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    image = Image.open(io.BytesIO(await file.read())).convert("RGB")
    img = transform(image).unsqueeze(0)

    with torch.no_grad():
        output = model(img)
        probs = torch.softmax(output, dim=1)[0]
        pred_idx = torch.argmax(probs).item()


    return {
    "Prediction": classes[pred_idx],
    "Confidence": round(float(probs[pred_idx] * 100), 2)
    }


