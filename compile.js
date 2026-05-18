import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import solc from 'solc';

const sourceCode = readFileSync('contracts/DegenGame.sol', 'utf8');

const input = {
  language: 'Solidity',
  sources: {
    'DegenGame.sol': {
      content: sourceCode
    }
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode.object']
      }
    }
  }
};

console.log('Compiling DegenGame contract...');
const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  const errors = output.errors.filter(e => e.severity === 'error');
  if (errors.length > 0) {
    console.error('Compilation errors:', errors);
    process.exit(1);
  }
}

const contract = output.contracts['DegenGame.sol']['DegenGame'];

if (!existsSync('build')) {
  mkdirSync('build');
}

writeFileSync('build/DegenGame.abi.json', JSON.stringify(contract.abi, null, 2));
writeFileSync('build/DegenGame.bytecode.json', JSON.stringify(contract.evm.bytecode.object));

console.log('Compilation successful! ABI and bytecode saved to build/ directory.');
