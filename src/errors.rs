use std::fmt::{self, Display, Formatter};
use std::io;
use std::error;
use std::result;

pub type Result<T> = result::Result<T, Error>;

#[derive(Debug)]
pub enum Error {
    Single(Box<dyn error::Error>),
    Chained(String, Box<dyn error::Error>),
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Error::Single(err) => write!(f, "{}", err),
            Error::Chained(context, err) => write!(f, "{}, caused by: \n{}", context, err),
        }
    }
}

impl error::Error for Error {}

impl From<&str> for Error {
    fn from(err: &str) -> Self {
        Error::Single(err.to_string().into())
    }
}

impl From<String> for Error {
    fn from(err: String) -> Self {
        Error::Single(err.into())
    }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Self {
        Error::Single(err.into())
    }
}

impl From<which::Error> for Error {
    fn from(err: which::Error) -> Self {
        Error::Single(err.into())
    }
}

pub trait ResultExt<T> {
    fn chain_err(self, err: impl Fn() -> String) -> Result<T>;
}

impl<T, E: error::Error + 'static> ResultExt<T> for result::Result<T, E> {
    fn chain_err(self, err: impl Fn() -> String) -> Result<T> {
        self.map_err(|source| Error::Chained(err(), source.into()))
    }
}
