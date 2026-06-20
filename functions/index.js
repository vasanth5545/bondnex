const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = getFirestore();

// 1. Send Partner Request
exports.sendpartnerrequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { partnerUid, senderName, senderProfileImageUrl } = request.data;
  if (!partnerUid || uid === partnerUid) {
    throw new HttpsError("invalid-argument", "Valid partner UID is required.");
  }

  // Check if partner exists
  const partnerDoc = await db.collection("users").doc(partnerUid).get();
  if (!partnerDoc.exists) {
    throw new HttpsError("not-found", "Partner user not found.");
  }

  // Check if either is already linked
  const userDoc = await db.collection("users").doc(uid).get();
  if (userDoc.data()?.linkedPartnerUid) {
    throw new HttpsError("failed-precondition", "You are already linked.");
  }
  if (partnerDoc.data()?.linkedPartnerUid) {
    throw new HttpsError("failed-precondition", "Partner is already linked.");
  }

  // Create or update a request document
  const requestRef = db.collection("love_requests").doc(`${uid}_${partnerUid}`);
  await requestRef.set({
    sender_uid: uid,
    receiver_uid: partnerUid,
    senderUid: uid, // for backward compatibility in CF
    receiverUid: partnerUid,
    sender_name: senderName || "Someone",
    sender_profile_image_url: senderProfileImageUrl || "",
    status: "pending",
    timestamp: FieldValue.serverTimestamp(),
    request_count: FieldValue.increment(1),
  }, { merge: true });

  return { success: true };
});

// 2. Accept Partner Request
exports.acceptpartnerrequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { senderUid } = request.data;
  if (!senderUid) {
    throw new HttpsError("invalid-argument", "Sender UID is required.");
  }

  const requestRef = db.collection("love_requests").doc(`${senderUid}_${uid}`);
  const requestDoc = await requestRef.get();

  if (!requestDoc.exists || requestDoc.data().status !== "pending") {
    throw new HttpsError("not-found", "Pending request not found.");
  }

  // Use a batch to link both users atomically
  const batch = db.batch();
  const userRef = db.collection("users").doc(uid);
  const senderRef = db.collection("users").doc(senderUid);

  batch.update(userRef, { linkedPartnerUid: senderUid, linkedAt: FieldValue.serverTimestamp() });
  batch.update(senderRef, { linkedPartnerUid: uid, linkedAt: FieldValue.serverTimestamp() });
  
  // Update request status
  batch.update(requestRef, { status: "accepted", acceptedAt: FieldValue.serverTimestamp() });

  // Cleanup: delete all other pending requests for this user to prevent spam
  const requests1 = await db.collection("love_requests").where("receiverUid", "==", uid).where("status", "==", "pending").get();
  requests1.docs.forEach(doc => { if (doc.id !== requestRef.id) batch.delete(doc.ref); });

  const requests2 = await db.collection("love_requests").where("receiver_uid", "==", uid).where("status", "==", "pending").get();
  requests2.docs.forEach(doc => { if (doc.id !== requestRef.id) batch.delete(doc.ref); });

  const requests3 = await db.collection("love_requests").where("senderUid", "==", uid).where("status", "==", "pending").get();
  requests3.docs.forEach(doc => batch.delete(doc.ref));

  const requests4 = await db.collection("love_requests").where("sender_uid", "==", uid).where("status", "==", "pending").get();
  requests4.docs.forEach(doc => batch.delete(doc.ref));

  await batch.commit();

  return { success: true };
});

// 3. Reject Partner Request
exports.rejectpartnerrequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { senderUid } = request.data;
  if (!senderUid) {
    throw new HttpsError("invalid-argument", "Sender UID is required.");
  }

  const requestRef = db.collection("love_requests").doc(`${senderUid}_${uid}`);
  const requestDoc = await requestRef.get();

  if (!requestDoc.exists || requestDoc.data().status !== "pending") {
    throw new HttpsError("not-found", "Pending request not found.");
  }

  await requestRef.update({ status: "rejected", rejectedAt: FieldValue.serverTimestamp() });

  return { success: true };
});

// 3.5 Cancel Partner Request
exports.cancelpartnerrequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { receiverUid } = request.data;
  if (!receiverUid) {
    throw new HttpsError("invalid-argument", "Receiver UID is required.");
  }

  const requestRef = db.collection("love_requests").doc(`${uid}_${receiverUid}`);
  const requestDoc = await requestRef.get();

  if (!requestDoc.exists || requestDoc.data().senderUid !== uid) {
    return { success: true }; // Already deleted or not yours
  }

  await requestRef.delete();

  return { success: true };
});

// Helper to generate consistent chat ID
function getChatId(uid1, uid2) {
  return uid1 < uid2 ? `${uid1}_${uid2}` : `${uid2}_${uid1}`;
}

// 4. Unlink Partner
exports.unlinkpartner = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  const partnerUid = userDoc.data()?.linkedPartnerUid;

  if (!partnerUid) {
    throw new HttpsError("failed-precondition", "You are not linked to anyone.");
  }

  const chatId = getChatId(uid, partnerUid);

  const batch = db.batch();
  batch.update(db.collection("users").doc(uid), { linkedPartnerUid: FieldValue.delete(), linkedAt: FieldValue.delete() });
  batch.update(db.collection("users").doc(partnerUid), { linkedPartnerUid: FieldValue.delete(), linkedAt: FieldValue.delete() });

  await batch.commit();

  // Atomically delete all chats and call logs
  await db.recursiveDelete(db.collection("chats").doc(chatId));
  await db.recursiveDelete(db.collection("call_logs").doc(chatId));

  return { success: true };
});

// 5. Delete Account
exports.deleteaccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    return { success: true };
  }

  const partnerUid = userDoc.data()?.linkedPartnerUid;

  if (partnerUid) {
    const chatId = getChatId(uid, partnerUid);
    
    // Remove link from partner
    await db.collection("users").doc(partnerUid).update({ linkedPartnerUid: FieldValue.delete(), linkedAt: FieldValue.delete() });
    
    // Delete shared chats and call logs
    await db.recursiveDelete(db.collection("chats").doc(chatId));
    await db.recursiveDelete(db.collection("call_logs").doc(chatId));
  }

  const batch = db.batch();

  // Clear love requests
  const requests1 = await db.collection("love_requests").where("senderUid", "==", uid).get();
  const requests2 = await db.collection("love_requests").where("receiverUid", "==", uid).get();
  requests1.docs.forEach(doc => batch.delete(doc.ref));
  requests2.docs.forEach(doc => batch.delete(doc.ref));

  const requests3 = await db.collection("love_requests").where("sender_uid", "==", uid).get();
  const requests4 = await db.collection("love_requests").where("receiver_uid", "==", uid).get();
  requests3.docs.forEach(doc => batch.delete(doc.ref));
  requests4.docs.forEach(doc => batch.delete(doc.ref));

  await batch.commit();

  // Delete storage directory for this user
  try {
    const bucket = admin.storage().bucket();
    await bucket.deleteFiles({ prefix: `users/${uid}/` });
  } catch(e) {
    console.error("Storage delete error:", e);
  }

  // Delete user document
  await db.recursiveDelete(userDoc.ref);
  
  return { success: true };
});

// ==========================================
// ENTERPRISE SECURITY & MONETIZATION
// ==========================================

const Razorpay = require("razorpay");
const crypto = require("crypto");

// 6. Check App Status (Versioning & Kill Switch)
exports.checkAppStatus = onCall(async (request) => {
  const configDoc = await db.collection("app_config").doc("version").get();
  if (!configDoc.exists) {
    return { minVersion: 1, latestVersion: 1, blockedVersions: [], maintenanceMode: false };
  }
  return configDoc.data();
});

// 7. Report Security Threat (RASP)
exports.reportSecurityThreat = onCall(async (request) => {
  const uid = request.auth?.uid || "unauthenticated";
  const { reason, appVersion, deviceId } = request.data;
  
  await db.collection("security_alerts").add({
    uid,
    reason: reason || "UNKNOWN_THREAT",
    appVersion: appVersion || "unknown",
    deviceId: deviceId || "unknown",
    timestamp: FieldValue.serverTimestamp(),
    ipAddress: request.rawRequest?.ip || "unknown"
  });

  return { success: true };
});

// 8. Create Razorpay Order
exports.createRazorpayOrder = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { planId } = request.data;
  if (!planId) {
    throw new HttpsError("invalid-argument", "Plan ID is required.");
  }

  let amount = 0;
  if (planId === "14_days") amount = 6900; // 69 INR in paise
  else if (planId === "30_days") amount = 9900;
  else throw new HttpsError("invalid-argument", "Invalid Plan ID.");

  // Using dummy keys for now, to be replaced by env vars in production
  const rzp = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID || "YOUR_KEY_ID",
    key_secret: process.env.RAZORPAY_KEY_SECRET || "YOUR_KEY_SECRET",
  });

  try {
    const order = await rzp.orders.create({
      amount,
      currency: "INR",
      receipt: `receipt_${uid}_${Date.now()}`
    });

    await db.collection("subscriptions").doc(order.id).set({
      uid,
      amount,
      status: "created",
      planId,
      createdAt: FieldValue.serverTimestamp()
    });

    return { orderId: order.id, amount: order.amount, currency: order.currency };
  } catch (error) {
    console.error("Razorpay Order Error:", error);
    throw new HttpsError("internal", "Failed to create order.");
  }
});

// 9. Verify Razorpay Payment Webhook
const { onRequest } = require("firebase-functions/v2/https");

exports.verifyPaymentWebhook = onRequest(async (req, res) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || "YOUR_WEBHOOK_SECRET";
  
  const shasum = crypto.createHmac("sha256", secret);
  shasum.update(JSON.stringify(req.body));
  const digest = shasum.digest("hex");

  if (digest === req.headers["x-razorpay-signature"]) {
    console.log("Webhook Signature Valid");
    const event = req.body.event;
    
    if (event === "payment.captured") {
      const payment = req.body.payload.payment.entity;
      const orderId = payment.order_id;

      const orderRef = db.collection("subscriptions").doc(orderId);
      const orderDoc = await orderRef.get();
      
      if (orderDoc.exists && orderDoc.data().status !== "paid") {
        await orderRef.update({
          status: "paid",
          razorpayPaymentId: payment.id,
          paidAt: FieldValue.serverTimestamp()
        });

        const uid = orderDoc.data().uid;
        const planId = orderDoc.data().planId;
        
        let days = 0;
        if (planId === "14_days") days = 14;
        else if (planId === "30_days") days = 30;

        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + days);

        await db.collection("users").doc(uid).collection("premium_status").doc("current").set({
          isPremium: true,
          planId,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          updatedAt: FieldValue.serverTimestamp()
        });
      }
    }
    res.status(200).send("OK");
  } else {
    res.status(400).send("Invalid Signature");
  }
});

// 10. Track Ad Progress
exports.trackAdProgress = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { targetPhoneNumber } = request.data;
  if (!targetPhoneNumber) {
    throw new HttpsError("invalid-argument", "Target Phone Number is required.");
  }

  const adRef = db.collection("users").doc(uid).collection("ad_unlocks").doc(targetPhoneNumber);
  const adDoc = await adRef.get();

  let adsWatched = 1;
  let unlockedAt = null;

  if (adDoc.exists) {
    const data = adDoc.data();
    adsWatched = (data.adsWatched || 0) + 1;
    if (adsWatched >= 3) {
      unlockedAt = FieldValue.serverTimestamp();
    }
  }

  await adRef.set({
    adsWatched,
    unlockedAt,
    updatedAt: FieldValue.serverTimestamp()
  }, { merge: true });

  return { adsWatched, isUnlocked: adsWatched >= 3 };
});

// 11. Reveal Phone Number (Zero Trust Unmasking)
exports.revealPhoneNumber = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { targetPhoneNumber } = request.data;
  if (!targetPhoneNumber) {
    throw new HttpsError("invalid-argument", "Target Phone Number is required.");
  }

  // 1. Check Premium Status
  const premiumRef = db.collection("users").doc(uid).collection("premium_status").doc("current");
  const premiumDoc = await premiumRef.get();
  
  let isPremium = false;
  if (premiumDoc.exists) {
    const data = premiumDoc.data();
    if (data.isPremium && data.expiresAt.toDate() > new Date()) {
      isPremium = true;
    }
  }

  // 2. Check Ad Unlocks if not Premium
  let isAdUnlocked = false;
  if (!isPremium) {
    const adRef = db.collection("users").doc(uid).collection("ad_unlocks").doc(targetPhoneNumber);
    const adDoc = await adRef.get();
    if (adDoc.exists && adDoc.data().unlockedAt != null) {
      isAdUnlocked = true;
    }
  }

  if (isPremium || isAdUnlocked) {
    return { success: true, phoneNumber: targetPhoneNumber };
  } else {
    throw new HttpsError("permission-denied", "You must buy Premium or watch 3 ads to unlock this number.");
  }
});
