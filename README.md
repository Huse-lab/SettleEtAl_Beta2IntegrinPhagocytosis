# DAAMP_Phagocytosis
Repository for code used to analyze data for Settle et al, 2024.
Within this repository are packages for analyzing imaging data to reproduce analyses presented by Settle et al in the manuscript "Beta2 Integrins Impose a Mechanical Checkpoint On Phagocytosis" for publication in...

Critical Note: This repository is strictly for the purpose of reproducing results from Settle et al 2024 (https://doi.org/10.1101/2024.02.20.580845). Some analysis parameters, such as thresholding defaults, channel identities, and meta-data parsing are specifically tailored to the experiments and analysis presented in the manuscript. For applied for use to new datasets or experiments, adjustments will be required. Contact authors for assisstance in this case.  


## Contents Overview

- Widefield Phagocytosis Analysis Code
- Widefield Phagocytosis Test Data
- Phagocytic Cup Polarization Analysis Code
- Phagocytic Cup Polarization Test Data

##  Widefield Phagocytosis Analysis Instructions
Main Script: Phagocytosis_BatchProcess_v3.m
Dependencies: Contained within Functions Folder
  - bfmatlab
  - createCirclesMask
  - labelParticles.m
  - makeSampleReport.m
  - processFrame.m
MATLAB Version: Developed and tested in MATALB 2022b, not tested on future versions

Raw Data Requirements:
Analysis code is written to specifically analyze live 2D (XYCT) microscopy datasets of macrophages engulfing DAAM paritcles labeled with FITC and LRB, captured and recorded using Zeiss software Zen Blue, output as a .czi files. It relies on four captured channels in this order: DAPI, FITC, TRITC and Brightfield. It can also handle data three-channel in order: FITC, TRITC, Brightfield, in which case it will only analyze particle statistics and not count macrophages.
Multiple .czi files can be processed in series, given they are deposited in the same directory.

To Run Analysis:
- Open MATLAB (2022b) and Set Path to include all folders in this repository
- Move .czi files of interest into the working directory
- Run first section: Select Folder For Processing
  * Select directory containing the .czi files of interest
- Run second section: Initialize Settings/Parameters
  * Input the time interval (120 for experiments presented)
  * Input the interval to be analysed (For faster processing of long movies, every 10 frames were analyzed. For particle tracking, in which every frame is analyzed, input 1)
  * Input the number of channels (3 or 4)
 
  * 
