const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp({
  projectId: "bondnex-0002" // from previous logs
});

const db = admin.firestore();

async function seedAdIds() {
  await db.collection("app_config").doc("monetization").set({
    android_rewarded_ad_id: "ca-app-pub-8068306737750378/9381716904",
    ios_rewarded_ad_id: "ca-app-pub-3940256099942544/1712485313",
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  console.log("Ad IDs seeded in Firestore successfully.");
}

seedAdIds().catch(console.error);
