# Graph Theory Analysis on EEG Data

A comprehensive MATLAB pipeline for analyzing EEG data using graph theory and network analysis techniques. This project processes raw EEG signals through multiple preprocessing stages, extracts connectivity features, and applies graph-theoretic measures to characterize brain network properties.

## Project Overview

This capstone project implements a complete workflow for EEG analysis with a focus on:
- **GPU-accelerated preprocessing** for efficient large-scale data processing
- **Advanced signal processing** including filtering, artifact removal, and dimensionality reduction
- **Connectivity analysis** using Phase Locking Value (PLV), Phase Lag Index (PLI), and Coherence measures
- **Graph theory metrics** for characterizing network topology and dynamics
- **Clinical applications** such as epilepsy detection and neurological assessment

## Pipeline Structure

The analysis pipeline is organized sequentially (A → I) for easy workflow management:

### Phase 1: Data Preprocessing
- **[A_preprocessing_gpu.m](A_preprocessing_gpu.m)** - GPU-accelerated EEG preprocessing
  - Load EDF files
  - Remove flat and highly correlated channels
  - Bandpass filtering (1-40 Hz)
  - Common Average Referencing (CAR)
  - Principal Component Analysis (PCA)
  - ICA-based artifact removal
  - Final data preparation

- **[B_count_samplingfrequency.m](B_count_samplingfrequency.m)** - Sampling frequency analysis
  - Detect sampling rate from raw data
  - Validate frequency consistency

- **[C_channel_reconstruction.m](C_channel_reconstruction.m)** - Channel reconstruction
  - Handle missing or corrupted channels
  - Reconstruct bipolar montages
  - Validate channel integrity

### Phase 2: Signal Analysis
- **[D_PSD.m](D_PSD.m)** - Power Spectral Density analysis
  - Compute PSD across frequency bands (delta, theta, alpha, beta, gamma)
  - Generate spectral plots and statistics

- **[E_feature_extraction_gpu.m](E_feature_extraction_gpu.m)** - GPU-accelerated feature extraction
  - Extract connectivity features (PLV, PLI, Coherence)
  - Compute band-specific power features
  - Generate correlation matrices
  - Support for frequency bands: delta [0.5-4 Hz], theta [4-8 Hz], alpha [8-13 Hz], beta [13-30 Hz], gamma [30+ Hz]

### Phase 3: Visualization & Network Analysis
- **[F_swarm_plot.m](F_swarm_plot.m)** - Statistical visualization
  - Generate swarm plots for group comparisons
  - Display distribution of network metrics across subjects

- **[G_graph_networks.m](G_graph_networks.m)** - Graph theory analysis
  - Compute advanced network metrics:
    - Clustering coefficient
    - Path length
    - Modularity
    - Small-worldness
  - Support for multiple thresholding methods (proportional, absolute, MST+)
  - Separate analysis for epilepsy and non-epilepsy groups

- **[H_network_analysis_topologyplots.m](H_network_analysis_topologyplots.m)** - Topology visualization
  - Generate publication-ready network visualizations
  - 10-20 electrode positioning in 2D/3D
  - Connectivity strength visualization
  - Topographical brain maps

- **[I_topographic_map_pipeline.m](I_topographic_map_pipeline.m)** - Topographic mapping
  - Generate heat maps of network properties
  - Electrode-based visualization
  - Spatial interpolation of metrics

## Key Features

### GPU Acceleration
- CUDA-enabled processing for preprocessing and feature extraction
- Significant speedup for large datasets
- Automatic fallback to CPU if GPU unavailable

### Connectivity Measures
- **Phase Locking Value (PLV)**: Measures phase synchronization between channels
- **Phase Lag Index (PLI)**: Asymmetric connectivity metric
- **Coherence**: Frequency-domain synchronization

### Graph Theory Metrics
- Network density and global efficiency
- Clustering coefficient (local integration)
- Characteristic path length (global integration)
- Small-world properties (σ = C/C_random ÷ L/L_random)
- Modularity and community detection
- Degree distribution analysis

### Frequency Band Analysis
- **Delta** (0.5-4 Hz): Deep sleep, unconsciousness
- **Theta** (4-8 Hz): Sleep, meditation
- **Alpha** (8-13 Hz): Relaxed wakefulness
- **Beta** (13-30 Hz): Active thinking
- **Gamma** (30+ Hz): Consciousness, perception

## Requirements

### Software
- MATLAB R2019b or later (or GNU Octave with compatible toolboxes)
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox (optional, for GPU acceleration)

### Hardware
- NVIDIA GPU with CUDA support (optional but recommended)
- Minimum 8 GB RAM (16 GB+ recommended for large datasets)

### Data Format
- EDF (European Data Format) files for raw EEG recordings
- 22-channel bipolar montage (standard for epilepsy datasets)
- 250 Hz sampling frequency (adaptable to other rates)

## Usage

### Basic Workflow

```matlab
% 1. Preprocess raw EEG data
[processed_data, fs, channels] = edf_to_mat('subject_01.edf');

% 2. Extract features
[plv_matrix, coherence_matrix, psd_matrix] = extract_features(processed_data, fs);

% 3. Apply graph analysis
metrics = compute_graph_metrics(plv_matrix, threshold_method='proportional', threshold=0.2);

% 4. Generate visualizations
plot_brain_network(metrics, electrode_positions);
```

### Configuration

Edit the base paths and parameters in each script:
```matlab
base_path = 'path/to/your/dataset';
groups = {'epilepsy', 'non_epilepsy'};
config.threshold_method = 'proportional';  % 'proportional', 'absolute', or 'mst_plus'
config.threshold_range = [0.20];  % 20% network density
```

## Output

The pipeline generates:
- **Processed data matrices** (.mat files)
- **Connectivity matrices** (PLV, PLI, Coherence)
- **Network metrics** (CSV format for statistical analysis)
- **Publication-ready visualizations** (PNG, PDF formats)
- **Statistical comparisons** between groups

## Clinical Applications

This analysis framework is designed for:
- **Epilepsy detection** and seizure prediction
- **Sleep disorder characterization**
- **Neurological assessment** in various pathologies
- **Brain network connectivity** research
- **Treatment outcome evaluation**

## References


## Author

Divya Eshwar, Jeevana Reddy, Harini B, Greeshma DH

## License

This project is provided for academic and research purposes.

## Notes

- Ensure all EDF files follow the standard format with proper header information
- GPU processing is optional; scripts will automatically use CPU if GPU is unavailable
- Thresholding methods significantly affect network metric interpretation; choose based on research question
- Always validate channel montages before analysis to ensure data quality
