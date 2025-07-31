# Contributing to Hoppscotch Self-Hosted Documentation

Thank you for your interest in contributing to the Hoppscotch Self-Hosted Documentation project!

## 🤝 How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or request features
- Provide clear descriptions and steps to reproduce
- Include environment details (OS, Docker version, etc.)

### Submitting Changes
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 Documentation Guidelines

### File Structure
- Keep the existing directory structure
- Place documentation in appropriate folders
- Use clear, descriptive filenames

### Writing Style
- Use clear, concise language
- Include code examples where helpful
- Add troubleshooting sections for complex setups
- Use proper markdown formatting

### Testing
- Test all deployment scripts before submitting
- Verify documentation accuracy
- Check that all links work

## 🧪 Testing Your Changes

### Local Testing
```bash
# Test basic setup
cd basic-setup && ./start.sh

# Test email setup
cd email-setup && ./start.sh

# Test AIO setup
cd aio-setup && ./start.sh
```

### AWS Testing
- Test EC2 deployment script
- Validate CloudFormation templates
- Verify ECS deployment process

## 📋 Pull Request Checklist

- [ ] Changes are tested and working
- [ ] Documentation is updated
- [ ] Code follows existing style
- [ ] Commit messages are clear
- [ ] No sensitive information is included

## 🆘 Getting Help

- Check existing issues and documentation
- Ask questions in GitHub Discussions
- Reference official Hoppscotch documentation

## 📚 Resources

- [Hoppscotch Official Docs](https://docs.hoppscotch.io/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Documentation](https://docs.aws.amazon.com/)

Thank you for contributing! 🎉
