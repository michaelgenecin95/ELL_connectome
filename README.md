# ELL_connectome
repository for ELL_connectome project!

Connectivity Analysis:
Connectivity wrapper runs analysis on cells downloaded from the shared 
google drive and creates an image of the connectivity between cells as 
well as a heatmap of connections by cell type. Be sure to download the 
cells locally and edit the path at the top of the script to your local 
path. 

connectivity_wrapper is the main wrapper script for analysis
connectivityMap is the funcion that generates the connectivity map
script_get_base_segs is for getting the base segments from CREST files

to do: report self-synapses (this is an error), print cell ID and annotation coordinates

In progress: double check any segment over laps to search for duplicate cells,
then merge data from duplicates to maximaize segment and synapse number

Completed: create a version of the heatmap with the unconnected cells removed

Other ideas for the project:
create a web-app for people to check a new cell against previously 
reconstructed cells online to avoid duplicates

