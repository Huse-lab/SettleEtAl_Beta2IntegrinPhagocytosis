# DAAMP_Phagocytosis
Repository for code used to analyze data for Settle et al, 2024 (https://doi.org/10.1101/2024.02.20.580845).
"Beta2 Integrins Impose a Mechanical Checkpoint On Phagocytosis" for publication in...

Critical Note: This repository is strictly for the purpose of reproducing results from Settle et al 2024. Some analysis parameters, such as thresholding defaults, channel identities, and meta-data parsing are specifically tailored to the experiments and analysis presented in the manuscript. For applied use to new datasets or experiments, adjustments will be required. Contact authors for assisstance if needed.  

General System Requirements: All analyses were running with MATLAB 2022b using Mac OS Venture (13). Code has also been tested on MATLAB 2022b on Windows 11. See https://www.mathworks.com/support/requirements/previous-releases.html for system requirements for MATLAB and installation instructions. 

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

Related Figures: 3K, 4E, S5D, 6E, 7F, S9D-E
 
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
For calculating actin coverage/phagocytic cup progress in Phagocytic stalling assays with DAAM particles labeled with AF488. NOTE: This script is a semi-automated MATLAB GUI. It uses automated segmentation to identify the particle in question and define its boundaries, but the cup position is determined by user inspection. The GUI allows for easier tracing of the cup position, and then calculates the actin coverage on the particle using the user-defined boundaries. 

Related Figures: 3H-I, 5G-H, 7C-D. This was also used to calculate Fraction Engulfed to filter data to only analyze <60% complete cups for actin/CD18/vinculin accumulation analyses above. 

Main Script: CupAdvancementInfrastructure.m

Dependencies: This analysis uses the data-handling infrastructure from https://gitlab.com/dvorselen/DAAMparticle_Shape_Analysis

MATLAB Version: 2022b

System Requirements: Enough RAM to hold all images analyzed in memory. Can be done in batches if necessary for computers with less RAM. For 16GB RAM, ~10 images per batch recommended.

Raw Data Requirements: This analysis code is written to analyze 3D confocal microscopy data from a Stellaris 8 with Lightning deconvolution saved as individual .tif files. It has been tested on both Lightning and Raw images. Rresults in the manuscript used Lightning images. 

To Run:
- Open MATLAB 2022b, and set path to include DAAMparticle_Shape_Analysis package
- Place all .tif files in directory of interest
    -  NOTE: This analysis holds all images in memory, so should be analyzed in batches if not using a computer with especially high RAM. For a standard 16GB RAM laptop, ~10-20 images at a time works fine. 
-  Run first section to load TIFs into memory
  - If ReadBFImages throws an error, there may be a pathing issue. Clear the MATLAB path to default and re-add DAAMParticle_Shape_Analysis
-  Run second section: Extract images and metadata
  - User will be prompted with two or more images, click on the image with the particle to identify the particle channel
  - Z-correction: Set to 1
  - Zero-padded values: Click "No"
- Run Main Loop. For each loaded image:
  - User prompted with a sliceViewer stack of the particle channel. Click on the center of the particle to indicate the XZ plane to analyze. You do not have to adjust the Z-slice to find the center, and chosen center can be approximate.
  - User presented with the maximum XZ-slice of the cell channel (actin). By clicking around the image, trace the outside of the phagocytic cup such that the cup is just enclosed in the resulting polygon. Double click to finish. If there is no visible cup, just trace a small rectangle below the lowest point of the cell. If there is a fully enclosed circle, trace the outside of that circle.
  - Repeat until the end of the list of images
- Run final section: Save output
  - User Prompt for output file name
  - Output: .mat structure "CupStats"
    - Fraction_Engulfed is the calculated actin coverage presented in the paper e.g. Figure 3H
    - partStats has volumetric information about the particle, this can be used for troubleshooting if results are unexpected.
    - cup_edge is the user-defined polygon of the phagocytic cup positions.
   

## Phagocytic Cup Actin Clearance GUI 
For analysis of actin/CD18 clearance at phagocytic cups on DAAM particles labeled with AF488. This script is a semi-automated MATLAB GUI that first uses the DAAMparticle_Shape-Analysis protocol to generate 3D reconstructions of the particles and identify stain signals on them. The protocol then presents line-traces of the stain signal on the phagocytic cup and the edges are defined by the user. These edges are used to define the central and outer regions of the phagocytic cup to calculate a clearance ratio, as defined in the methods.

Related Figures: S4G (demonstration of the process), 3L, 4F, S5E, 6F, 9C. 

Main Scripts: This section is split into multiple scripts to help with running multiple batches of images for large data sets: ActinStainOnParticle_Processing.m, ActinContent_Realign_andMakePlots.m, 

System Requirements: Enough RAM to hold images in memory. Highly recommended to run in batches smaller than 10 images for 16GB RAM. 

MATLAB Version: 2022b with Parallel Computing Toolbox

Dependencies: This analysis uses particle analysis infrastructure from https://gitlab.com/dvorselen/DAAMparticle_Shape_Analysis

Raw Data Requirements: This analysis code is written to analyze 3D confocal microscopy data from a Stellaris 8 with Lightning deconvolution saved as individual .tif files. It has been tested on both Lightning and Raw images. Rresults in the manuscript used Lightning images. 



To Run Analysis:

First Run ActinStainOnParticle_Processing.m:
This section is an adaptation of the particle-triangulation processing steps presented in [Vorselen et al 2020](https://doi.org/10.1038/s41467-019-13804-z) and [de Jesus & Settle et al 2024. ](https://www.science.org/doi/10.1126/sciimmunol.adj2898)
- Open MATLAB 2022b, and add DAAMparticle_Shape_Analysis package to path
- Place all .tif files into directory of interest
- Run First Section: Open UI to select files
  - Select Files to analyze
- Run Next Section: Extract the images and required metadata
  - User will be prompted with two or more images, click on the image with the particle to identify the particle channel
  - Z-correction: Set to 1
  - Zero-padded values: Click "No"
- Run Section: Threshold the images and identify particles (use all default options)
  - This will take ~1 minute for 5-10 images
- Run Section: Superlocalize particle edges and triangulate surface
  - Use all default options when presented
  - This may take a while depending on your system specifications. Expect ~5-10 minutes for standard system. 
- Run Section: Triangulate surface and determine particle statistics
- Run Section: Determine particle coverage by a secondary signal
- Run Section: Convert secondary signal to mask and align cups
  - This will sometimes warn you that signal-to-noise isn't good enough to properly mask. This is ok, as you will manually re-align the cups later.
- Run Section: Optionally get cd18 stain -- if images contain CD18 stain
- Run final section to remove large image data from MPRender structure and name/save output
  - MPStats structure contains the rendered particle data that is used in the following steps for analysis. This structure can also be mined for additional DAAM particle-related analyses if desired: see https://github.com/Huse-lab/Synapse-Profiling for more information.
 
Next, place MPRender structures into folder of interest and run ActinContent_Realign_andMakePlots.m
NOTE: this step will filter out particles that are completely engulfed and overwrite the MPRender file. Be sure to put a duplicate in another folder if you want to maintain the original structure.
- First Section: Load folder of MPRender files
- Main Loop
  - User will be prompted with a 3D-rendering of the particle with actin stain.
  - Click and drag such that the base of the phagocytic cup is facing the user (estimate centroid of contact area), this will re-align the particle so that the base of the cup is centered for the next analysis.
  - If particle is completely covered in Actin OR its too difficult to see any actin signal: click "Finished" this will remove the sample from the dataset.
  - If actin-coverage only partially covers the particle, click "Partial"
  - Repeat for each particle/image
- This will generate some preliminary plots of actin profiles. This is just for manual inspection and quality control.

Finally, run LineProfile_GUIOutput.m
- Run first section to load MPRenders
- Run Main Loop:
  - User presented with a line profile of actin/Cd18 intensity along the axis, centered around the phagocytic cup base defined above. Click on the left and right edge of the contact area (the first and last peak of actin/cd18 signal). Click as closely to the edge as possible. The Y position of the click doesn't matter, only X position.
  - Repeat for orthogonal line profile
  - Repeat with two line profiles for all particles
- Run final line to save table as a csv
- Each file should have two clearance ratios based on orthogonal line profiles, take the average of these to calculate the clearance ratios presented in the manuscript.


## Authors
Alex Settle (settlea@mskcc.org), Morgan Huse (husem@mskcc.org)
