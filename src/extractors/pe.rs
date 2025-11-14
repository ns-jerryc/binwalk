use crate::extractors::common::{Chroot, ExtractionResult, Extractor, ExtractorType};
use crate::structures::pe::parse_pe_file;

/// Defines the internal extractor function for carving out PE files
///
/// ```
/// use std::io::ErrorKind;
/// use std::process::Command;
/// use binwalk::extractors::common::ExtractorType;
/// use binwalk::extractors::pe::pe_extractor;
///
/// match pe_extractor().utility {
///     ExtractorType::None => panic!("Invalid extractor type of None"),
///     ExtractorType::Internal(func) => println!("Internal extractor OK: {:?}", func),
///     ExtractorType::External(cmd) => {
///         if let Err(e) = Command::new(&cmd).output() {
///             if e.kind() == ErrorKind::NotFound {
///                 panic!("External extractor '{}' not found", cmd);
///             } else {
///                 panic!("Failed to execute external extractor '{}': {}", cmd, e);
///             }
///         }
///     }
/// }
/// ```
pub fn pe_extractor() -> Extractor {
    Extractor {
        do_not_recurse: true,
        utility: ExtractorType::Internal(extract_pe_file),
        ..Default::default()
    }
}

/// Internal extractor for PE files
pub fn extract_pe_file(
    file_data: &[u8],
    offset: usize,
    output_directory: Option<&str>,
) -> ExtractionResult {
    const OUTFILE_NAME: &str = "executable.exe";

    let mut result = ExtractionResult {
        ..Default::default()
    };

    // Parse the PE file structure
    if let Ok(pe_file) = parse_pe_file(&file_data[offset..]) {
        // Set the size of the PE file
        result.size = Some(pe_file.size);
        result.success = true;

        // If output directory is specified, carve the file
        if output_directory.is_some() {
            let chroot = Chroot::new(output_directory);
            result.success = chroot.carve_file(OUTFILE_NAME, file_data, offset, pe_file.size);
        }
    }

    result
}
