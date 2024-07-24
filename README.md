# DAAMP_Phagocytosis
Repository for code used to analyze data for Settle et al, 2024.
Within this repository are packages for analyzing imaging data to reproduce analyses presented by Settle et al in the manuscript "Beta2 Integrins Impose a Mechanical Checkpoint On Phagocytosis" for publication in...

Critical Note: This repository is strictly for the purpose of reproducing results from Settle et al 2024 (https://doi.org/10.1101/2024.02.20.580845). Some analysis parameters, such as thresholding defaults, channel identities, and meta-data parsing are specifically tailored to the experiments and analysis presented in the manuscript. For applied use to new datasets or experiments, adjustments will be required. Contact authors for assisstance if needed.  


## Contents Overview

- Widefield Phagocytosis Analysis Code
- Phagocytic Cup Polarization Analysis Code
- Phagocytic Cup Advancement MATLAB GUI
- Phagocytic Cup Clearance Analysis GUI 

##  Widefield Phagocytosis Analysis Instructions
For calculating bulk phagocytic efficiency and phagocytic index, as well as tracking particle acidification rates. This analysis is fully-automated besides data curation and running the code. 

Related Figures: 2B,2C,S2B-F,S4C, S6B-C

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
  * Input the interval to be analysed (For faster processing of long movies, every 10 frames were analyzed. For particle tracking, in which every frame is analyzed, input 1. For demo purposes, choose 5)
  * Input the number of channels (3 or 4)
- Run Main Loop. This will take 1 minute per sample being analyzed. It will take significantly longer for longer movies or if analyzing every frame.
  * This will generate a MATLAB struct for each movie labeled "frameStruct" with the following data for each frame analyzed
    * xDim,yDim - size of image, in pixels
    * Circles2: a list of all identified particles in the frame with their location and size
    * LabeledImage: a matrix matching the xDim x yDim image with each identified particle labeled with a unique integer
    * TimeStamp: Time stamp in seconds
    * Num_Cells: Number of cells identified in frame using DAPI channel
    * Stats: sub structure with fluoresence values of Red (LRB) and Green (FITC) intensities of each identified particle in frame.
  * This structure will be used to analyze overall phagocytic efficiency and index (as in Figure 2B,C or Supp Figure 2).  The Stats sub-structure can be mined for additional insight on individual particle statistics over time (as in Supp Fig 4C)
- Run Sample Report 
  * This creates a .png with information on the before-and-after results, used for quality control and quick inspection of results. Upper Left: first frame analyzed, each particle identified colored according to FITC/LRB ratio. Upper Right: Final frame analyzed, colored according to FITC/LRB ratio. Middle left: Histogram of each particles FITC/LRB ratio during first and final frames. Middle Right: Histogram of all analyzed frames, with identified threshold as red line.
- Generate Output Tables
  * This will generate an individual csv file for each of thhe following four calculated values:
    * NumCells - total cells identified in frame
    * TotalParticles - total number of DAAM particles identified in frame
    * Acidified Particles - Number of DAAM particles with FITC/LRB ratios below calculated threshold in frame
    * Phagocytic Efficiency - Acidified Particles divided by Total Particles
  * Phagocytic index can also be calculated as Acidified Particles / Num Cells
  * Rows in each table represent time points analyzed, each column represents a sample analyzed. For single sample analyses, there will only be one column.
 
 ##  Confocal Microscopy Phagocytic Cup Polarization Analysis Instructions
For calculating Actin, Vinculin or CD18 accumulation ratios. This analysis is fully automated, besides data curation and running the code. 

Related Figures: 3K, 4E, S5D, 6E, 7F, S9D
 
 Main Script: PhagocyticCupQuantification_v4.m

 Dependencies: Contained within Functions Folder

 MATLAB Version: 2022b

Raw Data Requirements: This analysis code is written to analyze 3D confocal microscopy data from a Stellaris 8 with Lightning deconvolution saved as individual .tif files. The v4 version included here uses both the Lightning devoncoluted and Raw data for analysis. The Lightning file (file ending in '_Lng.tif') is used for particle thesholding and segmenting to define the cup-cell interface, while intensity values are extracted from the Raw file (same label, without _Lng.tif). The Lightning and raw files must be in the same folder with the same name except for the Lng identifier. The code will check at the start and throw a warning for any missing Lng or raw files. 


 To Run Analysis:
 - Open MATLAB 2022b and set path to include all dependencies
 - Place all .tif files (both raw and Lng) into a directory of interest.
 - Run the first section, select the directory of interest
 - Run the second section, this will prompt you to identify which channel contains the particle
 - Run the Main Loop. The runtime will depend on a number of factors. The rate-limiting step will be load each image into MATLAB, which is dependent on file size and whether it is being loaded locally or from a server. For the demo files included, it should take between 5-10 seconds per image to analyze.
 - At the end of the loop, the code will generate a table with results for each analyzed sample. Each row corresponds to one sample:
   * TotalStain and TotalStainRaw: mean fluoresence intensity of measured stain within the bounds of the whole cell, as identified by thresholding described in the methods. TotalStain extracts value directly from Lightning deconvoluted file and TotalStainRaw extracts directly from the Raw image file.
   * ParticleStain and ParticleStainRaw: mean fluoresence intensity of the measured stain at the interface of particle and cell
   * Ignore all other fields, as they are vestigial and not relevant for analysis here.
If the image contains two color channels, it will assume that the stain of interest is contained in the channel not indicated to be the particle (specified in the second section)
If the image contains more than two color channels, it will run the analysis for all additional stains labeled Stain1, Stain2, Stain3... In this case, it will also calculate a correlation between Stain1 and Stain2 (see Figure S5D)
This table can be used to generate the ratios described in the paper. Accumulation Ratio is defined as ParticleStainRaw / TotalStainRaw.


## Phagocytic Cup Advancement GUI 
For calculating actin coverage/phagocytic cup progress in Phagocytic stalling assays. NOTE: This script is a semi-automated MATLAB GUI. It uses automated segmentation to identify the particle in question and define its boundaries, but the cup position is determined by user inspection. The GUI allows for easier tracing of the cup position, and then calculates the actin coverage on the particle using the user-defined boundaries. 

Related Figures: 3H-I, 5G-H, 7C-D

Main Script: CupAdvancementInfrastructure.m

Dependencies: This analysis uses the data-handling infrastructure from https://gitlab.com/dvorselen/DAAMparticle_Shape_Analysis

 MATLAB Version: 2022b

Raw Data Requirements: This analysis code is written to analyze 3D confocal microscopy data from a Stellaris 8 with Lightning deconvolution saved as individual .tif files. 
