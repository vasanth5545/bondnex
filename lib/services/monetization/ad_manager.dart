import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  String? _adUnitId;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    await _fetchAdUnitId();
  }

  Future<void> _fetchAdUnitId() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('monetization').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _adUnitId = Platform.isAndroid 
              ? data['android_rewarded_ad_id']?.toString()
              : data['ios_rewarded_ad_id']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetching Ad Unit ID: $e');
    }
  }

  void loadRewardedAd() {
    if (_adUnitId == null) {
      debugPrint('Ad Unit ID not loaded. Call loadRewardedAd later.');
      return;
    }
    RewardedAd.load(
      adUnitId: _adUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  void showRewardedAd(String targetPhoneNumber, Function(bool, int) onRewardEarned) {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      debugPrint('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
      
      // Call Zero Trust backend to log progress securely
      try {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('trackAdProgress');
        final result = await callable.call(<String, dynamic>{
          'targetPhoneNumber': targetPhoneNumber,
        });

        final adsWatched = result.data['adsWatched'] as int;
        final isUnlocked = result.data['isUnlocked'] as bool;

        onRewardEarned(isUnlocked, adsWatched);
      } catch (e) {
        debugPrint("Error tracking ad progress: $e");
      }
    });
    _rewardedAd = null;
  }
}
